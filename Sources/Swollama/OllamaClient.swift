#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation


public actor OllamaClient: OllamaProtocol {
    public let baseURL: URL
    public nonisolated let configuration: OllamaConfiguration

    private let session: URLSession
    let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(baseURL: URL = URL(string: "http://localhost:11434")!, configuration: OllamaConfiguration = .default) {
        self.baseURL = baseURL
        self.configuration = configuration

        let config = NetworkingSupport.createDefaultConfiguration()
        config.timeoutIntervalForRequest = configuration.timeoutInterval

        self.session = NetworkingSupport.createSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }








    func makeRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent("/api").appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        var lastError: Error?
        for attempt in 0...configuration.maxRetries {
            do {
                let (data, response) = try await NetworkingSupport.dataTask(session: session, for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OllamaError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 404:
                    throw OllamaError.modelNotFound
                case 400:
                    if let errorMessage = String(data: data, encoding: .utf8) {
                        throw OllamaError.invalidParameters(errorMessage)
                    }
                    throw OllamaError.invalidParameters("Unknown error")
                case 500...599:
                    if let errorMessage = String(data: data, encoding: .utf8) {
                        throw OllamaError.serverError(errorMessage)
                    }
                    throw OllamaError.serverError("Unknown server error")
                default:
                    throw OllamaError.unexpectedStatusCode(httpResponse.statusCode)
                }
            } catch {
                lastError = error

                let shouldRetry: Bool
                if let ollamaError = error as? OllamaError {
                    switch ollamaError {
                    case .serverError, .networkError:
                        shouldRetry = true
                    default:
                        shouldRetry = false
                    }
                } else {
                    shouldRetry = true
                }

                if shouldRetry && attempt < configuration.maxRetries {
                    try await Task.sleep(for: .seconds(configuration.retryDelay))
                    continue
                }

                throw error
            }
        }

        throw OllamaError.networkError(lastError ?? URLError(.unknown))
    }








    func streamRequest<T: Decodable>(
        endpoint: String,
        method: String = "POST",
        body: Data?,
        as type: T.Type
    ) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = baseURL.appendingPathComponent("/api").appendingPathComponent(endpoint)
                    var request = URLRequest(url: url)
                    request.httpMethod = method
                    request.httpBody = body
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let (dataStream, response) = try await NetworkingSupport.enhancedStreamTask(session: session, for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OllamaError.invalidResponse
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        var errorBody = Data()
                        for try await chunk in dataStream {
                            errorBody.append(chunk)
                            if errorBody.count > 4096 { break }
                        }

                        let errorMessage = String(data: errorBody, encoding: .utf8) ?? "Unknown error"

                        switch httpResponse.statusCode {
                        case 404:
                            throw OllamaError.modelNotFound
                        case 400:
                            throw OllamaError.invalidParameters(errorMessage)
                        case 500...599:
                            throw OllamaError.serverError(errorMessage)
                        default:
                            throw OllamaError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                    }

                    var buffer = Data()
                    let newline = UInt8(ascii: "\n")

                    for try await chunk in dataStream {
                        buffer.append(chunk)


                        while let newlineIndex = buffer.firstIndex(of: newline) {
                            let lineData = buffer[..<newlineIndex]
                            if !lineData.isEmpty {
                                do {
                                    let decoded = try decoder.decode(T.self, from: lineData)
                                    continuation.yield(decoded)
                                } catch {
                                    continuation.finish(throwing: OllamaError.decodingError(error))
                                    return
                                }
                            }

                            buffer.removeSubrange(...newlineIndex)
                        }
                    }


                    if !buffer.isEmpty {
                        do {
                            let decoded = try decoder.decode(T.self, from: buffer)
                            continuation.yield(decoded)
                        } catch {
                            continuation.finish(throwing: OllamaError.decodingError(error))
                            return
                        }
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
    }





    public func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw OllamaError.invalidParameters("Failed to encode request: \(error.localizedDescription)")
        }
    }







    public func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw OllamaError.decodingError(error)
        }
    }
}
