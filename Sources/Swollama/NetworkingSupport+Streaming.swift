import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension NetworkingSupport {

    static func enhancedStreamTask(
        session: URLSession,
        for request: URLRequest
    ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
        #if os(Linux)

            return try await curlStreamTask(for: request)
        #else

            return try await streamTask(session: session, for: request)
        #endif
    }

    #if os(Linux)

        private static func curlStreamTask(
            for request: URLRequest
        ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            var curlArgs = [
                "-X", request.httpMethod ?? "GET",
                url.absoluteString,
                "-H", "Content-Type: application/json",
                "-N",
                "--no-buffer",
                "-s",
                "-i",
                "--max-time", "300",
                "-w", "\\n\\n__CURL_HTTP_CODE__:%{http_code}",
            ]

            var tempFileURL: URL?
            if let httpBody = request.httpBody, !httpBody.isEmpty {
                let tempFile = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("json")
                try httpBody.write(to: tempFile)
                tempFileURL = tempFile
                curlArgs.append(contentsOf: ["-d", "@\(tempFile.path)"])
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            process.arguments = curlArgs

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()

            actor ResponseHolder {
                var response: HTTPURLResponse?

                func setResponse(_ response: HTTPURLResponse) {
                    self.response = response
                }

                func getResponse() -> HTTPURLResponse? {
                    return response
                }
            }

            let responseHolder = ResponseHolder()

            let stream = AsyncThrowingStream<Data, Error> { continuation in
                Task { [tempFileURL] in
                    let handle = pipe.fileHandleForReading
                    defer {
                        try? handle.close()
                    }
                    var headerData = Data()
                    var headersParsed = false

                    while process.isRunning || handle.availableData.count > 0 {
                        let chunk = handle.availableData

                        if chunk.isEmpty {

                            try? await Task.sleep(for: .milliseconds(10))
                            continue
                        }

                        if !headersParsed {

                            headerData.append(chunk)

                            let doubleCRLF = Data([13, 10, 13, 10])
                            let doubleLF = Data([10, 10])

                            if let separatorRange = headerData.range(of: doubleCRLF)
                                ?? headerData.range(of: doubleLF)
                            {

                                let headersData = headerData[..<separatorRange.lowerBound]
                                if let headers = String(data: headersData, encoding: .utf8) {
                                    headersParsed = true

                                    var statusCode = 200
                                    if let statusLine = headers.split(separator: "\n").first {
                                        let parts = statusLine.split(separator: " ")
                                        if parts.count >= 2, let code = Int(parts[1]) {
                                            statusCode = code
                                        }
                                    }

                                    if let httpResponse = HTTPURLResponse(
                                        url: url,
                                        statusCode: statusCode,
                                        httpVersion: "HTTP/1.1",
                                        headerFields: parseHeaders(from: headers)
                                    ) {
                                        await responseHolder.setResponse(httpResponse)
                                    }

                                    let bodyStartIndex = separatorRange.upperBound
                                    if bodyStartIndex < headerData.count {
                                        let bodyData = headerData[bodyStartIndex...]
                                        if !bodyData.isEmpty {
                                            continuation.yield(Data(bodyData))
                                        }
                                    }
                                }
                            }
                        } else {

                            if let chunkString = String(data: chunk, encoding: .utf8),
                                chunkString.contains("__CURL_HTTP_CODE__:")
                            {

                                if let markerRange = chunkString.range(
                                    of: "\n\n__CURL_HTTP_CODE__:"
                                ) {
                                    let actualData = String(chunkString[..<markerRange.lowerBound])
                                    if let data = actualData.data(using: .utf8), !data.isEmpty {
                                        continuation.yield(data)
                                    }
                                }
                            } else {
                                continuation.yield(chunk)
                            }
                        }
                    }

                    process.waitUntilExit()

                    if let tempFileURL = tempFileURL {
                        try? FileManager.default.removeItem(at: tempFileURL)
                    }

                    if process.terminationStatus != 0 {
                        continuation.finish(throwing: URLError(.unknown))
                    } else {
                        continuation.finish()
                    }
                }

                continuation.onTermination = { @Sendable [tempFileURL] _ in
                    if process.isRunning {
                        process.terminate()
                        process.waitUntilExit()
                    }

                    if let tempFileURL = tempFileURL {
                        try? FileManager.default.removeItem(at: tempFileURL)
                    }
                }
            }

            for attempt in 0..<20 {
                if let response = await responseHolder.getResponse() {
                    return (stream, response as URLResponse)
                }
                let delay = min(50, 1 << attempt)
                try await Task.sleep(for: .milliseconds(UInt64(delay)))
            }

            guard
                let fallbackResponse = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )
            else {
                throw URLError(.badServerResponse)
            }

            return (stream, fallbackResponse as URLResponse)
        }

        private static func parseHeaders(from headerString: String) -> [String: String] {
            var headers: [String: String] = [:]

            let lines = headerString.split(separator: "\n").dropFirst()
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
