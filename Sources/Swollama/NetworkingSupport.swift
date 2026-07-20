import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

enum NetworkingSupport {

    static let streamBufferSize = 65536

    static func createSession(
        configuration: URLSessionConfiguration,
        allowsInsecureConnections: Bool = false
    ) -> URLSession {
        #if !os(Linux)
            if allowsInsecureConnections {
                return URLSession(
                    configuration: configuration,
                    delegate: InsecureTrustDelegate(),
                    delegateQueue: nil
                )
            }
        #endif
        return URLSession(configuration: configuration)
    }

    static func createDefaultConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default

        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        #if !os(Linux)
            config.allowsExpensiveNetworkAccess = true
            config.allowsConstrainedNetworkAccess = true
            config.waitsForConnectivity = false
        #endif

        return config
    }

    static func dataTask(
        session: URLSession,
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)

            return try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data = data, let response = response else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (data, response))
                }
                task.resume()
            }
        #else

            return try await session.data(for: request)
        #endif
    }

    static func streamTask(
        session: URLSession,
        for request: URLRequest
    ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
        #if canImport(FoundationNetworking)

            let (data, response) = try await dataTask(session: session, for: request)

            let stream = AsyncThrowingStream<Data, Error> { continuation in
                Task {
                    let chunkSize = streamBufferSize
                    var offset = 0

                    while offset < data.count {
                        let end = min(offset + chunkSize, data.count)
                        let chunk = data[offset..<end]
                        continuation.yield(Data(chunk))
                        offset = end

                        try? await Task.sleep(for: .microseconds(100))
                    }

                    continuation.finish()
                }
            }

            return (stream, response)
        #else

            let (bytes, response) = try await session.bytes(for: request)
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                let task = Task {
                    do {
                        var buffer = Data(capacity: streamBufferSize)
                        let newline = UInt8(ascii: "\n")
                        for try await byte in bytes {
                            buffer.append(byte)
                            if byte == newline || buffer.count >= streamBufferSize {
                                continuation.yield(buffer)
                                buffer.removeAll(keepingCapacity: true)
                            }
                        }
                        if !buffer.isEmpty {
                            continuation.yield(buffer)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { @Sendable _ in
                    task.cancel()
                }
            }
            return (stream, response)
        #endif
    }
}

#if !os(Linux)
    /// A session delegate that accepts self-signed / otherwise-untrusted server certificates.
    ///
    /// Installed only when ``OllamaConfiguration/allowsInsecureConnections`` is `true`.
    final class InsecureTrustDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
        func urlSession(
            _ session: URLSession,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler:
                @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            if challenge.protectionSpace.authenticationMethod
                == NSURLAuthenticationMethodServerTrust,
                let trust = challenge.protectionSpace.serverTrust
            {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
#endif
