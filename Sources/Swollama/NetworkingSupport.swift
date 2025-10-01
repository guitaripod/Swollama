






#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation


enum NetworkingSupport {

    static let streamBufferSize = 65536


    static func createSession(configuration: URLSessionConfiguration) -> URLSession {
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
            Task {
                do {
                    var buffer = Data(capacity: streamBufferSize)
                    for try await byte in bytes {
                        buffer.append(byte)
                        if buffer.count >= streamBufferSize {
                            continuation.yield(buffer)
                            buffer = Data(capacity: streamBufferSize)
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
        }
        return (stream, response)
        #endif
    }
}

