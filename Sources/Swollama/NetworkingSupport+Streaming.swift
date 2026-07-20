import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension NetworkingSupport {

    static func enhancedStreamTask(
        session: URLSession,
        for request: URLRequest,
        configuration: OllamaConfiguration
    ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
        #if os(Linux)
            return try await curlStreamTask(for: request, configuration: configuration)
        #else
            return try await streamTask(session: session, for: request)
        #endif
    }

    #if os(Linux)

        /// A latch that lets ``curlStreamTask`` return the real parsed HTTP response (or a transport
        /// failure) instead of fabricating a `200` when headers are slow to arrive.
        private actor ResponseLatch {
            private var result: Result<HTTPURLResponse, Error>?
            private var waiters: [CheckedContinuation<HTTPURLResponse, Error>] = []

            func resolve(_ value: Result<HTTPURLResponse, Error>) {
                guard result == nil else { return }
                result = value
                let pending = waiters
                waiters.removeAll()
                for waiter in pending { waiter.resume(with: value) }
            }

            func value() async throws -> HTTPURLResponse {
                if let result { return try result.get() }
                return try await withCheckedThrowingContinuation { waiters.append($0) }
            }
        }

        /// Collects the curl subprocess's `stderr` so real failure diagnostics can be surfaced.
        private actor StderrBuffer {
            private var data = Data()
            func append(_ chunk: Data) { data.append(chunk) }
            func string() -> String {
                (String(data: data, encoding: .utf8) ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        private struct CurlStreamError: LocalizedError {
            let code: Int32
            let message: String
            var errorDescription: String? {
                message.isEmpty
                    ? "curl streaming request failed (exit code \(code))"
                    : "curl streaming request failed (exit code \(code)): \(message)"
            }
        }

        private static func curlStreamTask(
            for request: URLRequest,
            configuration: OllamaConfiguration
        ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            var curlArgs = [
                "-X", request.httpMethod ?? "GET",
                url.absoluteString,
                "-N",
                "--no-buffer",
                "-s",
                "-S",
                "-i",
                "--connect-timeout", "\(max(1, Int(configuration.timeoutInterval)))",
                "--keepalive-time", "60",
                "--speed-limit", "1",
                "--speed-time", "\(max(1, Int(configuration.streamTimeoutInterval)))",
            ]

            if configuration.allowsInsecureConnections {
                curlArgs.append("-k")
            }

            for (field, value) in request.allHTTPHeaderFields ?? [:] {
                curlArgs.append(contentsOf: ["-H", "\(field): \(value)"])
            }

            var tempFileURL: URL?
            if let httpBody = request.httpBody, !httpBody.isEmpty {
                let tempFile = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("json")
                do {
                    try httpBody.write(to: tempFile)
                } catch {
                    throw OllamaError.fileError(
                        "Failed to stage request body: \(error.localizedDescription)"
                    )
                }
                tempFileURL = tempFile
                curlArgs.append(contentsOf: ["-d", "@\(tempFile.path)"])
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            process.arguments = curlArgs

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            do {
                try process.run()
            } catch {
                if let tempFileURL { try? FileManager.default.removeItem(at: tempFileURL) }
                throw OllamaError.networkError(error)
            }

            let latch = ResponseLatch()
            let stderrBuffer = StderrBuffer()

            let stream = AsyncThrowingStream<Data, Error> { continuation in
                let stderrTask = Task {
                    let handle = errPipe.fileHandleForReading
                    while true {
                        let chunk = handle.availableData
                        if chunk.isEmpty { break }
                        await stderrBuffer.append(chunk)
                    }
                    try? handle.close()
                }

                let readTask = Task { [tempFileURL] in
                    let handle = outPipe.fileHandleForReading
                    var headerData = Data()
                    var headersParsed = false

                    while true {
                        let chunk = handle.availableData
                        if chunk.isEmpty { break }

                        if headersParsed {
                            continuation.yield(chunk)
                            continue
                        }

                        headerData.append(chunk)
                        let doubleCRLF = Data([13, 10, 13, 10])
                        let doubleLF = Data([10, 10])
                        guard
                            let separator = headerData.range(of: doubleCRLF)
                                ?? headerData.range(of: doubleLF)
                        else {
                            continue
                        }

                        headersParsed = true
                        let headerBytes = headerData[..<separator.lowerBound]
                        let headerString = String(data: headerBytes, encoding: .utf8) ?? ""
                        guard let httpResponse = makeResponse(url: url, headerString: headerString)
                        else {
                            let error = OllamaError.invalidResponse
                            await latch.resolve(.failure(error))
                            continuation.finish(throwing: error)
                            try? handle.close()
                            if process.isRunning { process.terminate() }
                            if let tempFileURL {
                                try? FileManager.default.removeItem(at: tempFileURL)
                            }
                            return
                        }
                        await latch.resolve(.success(httpResponse))

                        let bodyStart = separator.upperBound
                        if bodyStart < headerData.endIndex {
                            let initialBody = headerData[bodyStart...]
                            if !initialBody.isEmpty {
                                continuation.yield(Data(initialBody))
                            }
                        }
                        headerData = Data()
                    }

                    try? handle.close()
                    process.waitUntilExit()
                    _ = await stderrTask.value

                    if let tempFileURL {
                        try? FileManager.default.removeItem(at: tempFileURL)
                    }

                    let status = process.terminationStatus
                    if !headersParsed {
                        let error = OllamaError.networkError(
                            CurlStreamError(code: status, message: await stderrBuffer.string())
                        )
                        await latch.resolve(.failure(error))
                        continuation.finish(throwing: error)
                    } else if status != 0 {
                        continuation.finish(
                            throwing: OllamaError.networkError(
                                CurlStreamError(code: status, message: await stderrBuffer.string())
                            )
                        )
                    } else {
                        continuation.finish()
                    }
                }

                continuation.onTermination = { @Sendable [tempFileURL] _ in
                    readTask.cancel()
                    stderrTask.cancel()
                    if process.isRunning {
                        process.terminate()
                    }
                    if let tempFileURL {
                        try? FileManager.default.removeItem(at: tempFileURL)
                    }
                }
            }

            let response = try await withTaskCancellationHandler {
                try await latch.value()
            } onCancel: {
                if process.isRunning { process.terminate() }
                Task { await latch.resolve(.failure(CancellationError())) }
            }
            return (stream, response as URLResponse)
        }

        private static func makeResponse(url: URL, headerString: String) -> HTTPURLResponse? {
            var statusCode = 200
            if let statusLine = headerString.split(whereSeparator: { $0 == "\n" || $0 == "\r" })
                .first
            {
                let parts = statusLine.split(separator: " ")
                if parts.count >= 2, let code = Int(parts[1]) {
                    statusCode = code
                }
            }
            return HTTPURLResponse(
                url: url,
                statusCode: min(max(statusCode, 100), 599),
                httpVersion: "HTTP/1.1",
                headerFields: parseHeaders(from: headerString)
            )
        }

        private static func parseHeaders(from headerString: String) -> [String: String] {
            var headers: [String: String] = [:]

            let lines = headerString.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).dropFirst()
            for line in lines {
                if let colonIndex = line.firstIndex(of: ":") {
                    let key = line[..<colonIndex].trimmingCharacters(in: .whitespaces)
                    let value = line[line.index(after: colonIndex)...].trimmingCharacters(
                        in: .whitespaces
                    )
                    headers[key] = value
                }
            }

            return headers
        }
    #endif
}
