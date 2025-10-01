#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

/// A thread-safe client for interacting with the Ollama API.
///
/// `OllamaClient` is an actor that provides a comprehensive Swift interface to the Ollama API,
/// enabling text generation, chat completions, embeddings, and model management operations.
/// All methods are `async` and automatically serialized through the actor's isolation domain,
/// ensuring thread-safe access.
///
/// ## Overview
///
/// The client supports all major Ollama API operations:
/// - Text generation with streaming responses
/// - Chat completions with tool support
/// - Vector embeddings generation
/// - Model management (list, pull, push, delete, copy)
/// - Running model inspection
/// - Blob management for custom models
///
/// ## Platform Support
///
/// The client works on both macOS and Linux:
/// - **macOS/iOS**: Uses native `URLSession.bytes(for:)` for streaming
/// - **Linux**: Uses curl subprocess for HTTP streaming due to Foundation limitations
///
/// ## Example
///
/// ```swift
/// let client = OllamaClient()
///
/// guard let model = OllamaModelName.parse("llama3.2") else {
///     throw OllamaError.invalidParameters("Invalid model name")
/// }
///
/// for try await response in try await client.generateText(
///     prompt: "Tell me a joke",
///     model: model
/// ) {
///     print(response.response, terminator: "")
/// }
/// ```
///
/// - Note: As an actor, all method calls to `OllamaClient` must use `await`.
public actor OllamaClient: OllamaProtocol {
    /// The base URL for the Ollama API server.
    public let baseURL: URL

    /// Configuration settings for the client including timeouts, retries, and keep-alive behavior.
    public nonisolated let configuration: OllamaConfiguration

    private let session: URLSession
    let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Creates a new Ollama client.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL of the Ollama server. Defaults to `http://localhost:11434`.
    ///   - configuration: Client configuration including timeouts and retry behavior. Defaults to ``OllamaConfiguration/default``.
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

    init(
        baseURL: URL,
        configuration: OllamaConfiguration,
        session: URLSession
    ) {
        self.baseURL = baseURL
        self.configuration = configuration
        self.session = session

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





    /// Encodes a value to JSON data.
    ///
    /// - Parameter value: The encodable value to convert to JSON.
    /// - Returns: The JSON-encoded data.
    /// - Throws: ``OllamaError/invalidParameters(_:)`` if encoding fails.
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw OllamaError.invalidParameters("Failed to encode request: \(error.localizedDescription)")
        }
    }

    /// Decodes JSON data to a specified type.
    ///
    /// - Parameters:
    ///   - data: The JSON data to decode.
    ///   - type: The type to decode to.
    /// - Returns: The decoded value.
    /// - Throws: ``OllamaError/decodingError(_:)`` if decoding fails.
    public func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw OllamaError.decodingError(error)
        }
    }
}
