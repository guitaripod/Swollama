import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

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
    public init(
        baseURL: URL = URL(string: "http://localhost:11434")!,
        configuration: OllamaConfiguration = .default
    ) {
        self.baseURL = baseURL
        self.configuration = configuration

        let config = NetworkingSupport.createDefaultConfiguration()
        config.timeoutIntervalForRequest = configuration.timeoutInterval

        self.session = NetworkingSupport.createSession(
            configuration: config,
            allowsInsecureConnections: configuration.allowsInsecureConnections
        )

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = OllamaDate.parse(string) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Timestamp '\(string)' is not a valid RFC 3339 date"
                    )
                )
            }
            return date
        }

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
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = OllamaDate.parse(string) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Timestamp '\(string)' is not a valid RFC 3339 date"
                    )
                )
            }
            return date
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    nonisolated func applyStandardHeaders(to request: inout URLRequest, hasBody: Bool) {
        if hasBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
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
        applyStandardHeaders(to: &request, hasBody: body != nil)

        var lastError: Error?
        for attempt in 0...configuration.maxRetries {
            do {
                let (data, response) = try await NetworkingSupport.dataTask(
                    session: session,
                    for: request
                )

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OllamaError.invalidResponse
                }

                if let error = OllamaError.fromServer(
                    statusCode: httpResponse.statusCode,
                    body: data,
                    retryAfter: Self.retryAfterSeconds(from: httpResponse)
                ) {
                    throw error
                }
                return data
            } catch {
                lastError = error

                let shouldRetry: Bool
                var explicitDelay: TimeInterval?
                if let ollamaError = error as? OllamaError {
                    switch ollamaError {
                    case .serverError, .networkError:
                        shouldRetry = true
                    case .rateLimited(let retryAfter):
                        shouldRetry = true
                        explicitDelay = retryAfter
                    default:
                        shouldRetry = false
                    }
                } else {
                    shouldRetry = true
                }

                if shouldRetry && attempt < configuration.maxRetries {
                    let delay =
                        explicitDelay
                        ?? Self.backoffDelay(base: configuration.retryDelay, attempt: attempt)
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }

                throw error
            }
        }

        throw OllamaError.networkError(lastError ?? URLError(.unknown))
    }

    /// Parses a numeric `Retry-After` header into seconds.
    static func retryAfterSeconds(from response: HTTPURLResponse) -> TimeInterval? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        return TimeInterval(value.trimmingCharacters(in: .whitespaces))
    }

    /// Computes an exponential backoff delay with jitter, capped at 30 seconds.
    static func backoffDelay(base: TimeInterval, attempt: Int) -> TimeInterval {
        let capped = min(base * pow(2.0, Double(attempt)), 30)
        return capped + Double.random(in: 0...(capped * 0.25))
    }

    func streamRequest<T: Decodable & Sendable>(
        endpoint: String,
        method: String = "POST",
        body: Data?,
        as type: T.Type
    ) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = baseURL.appendingPathComponent("/api").appendingPathComponent(
                        endpoint
                    )
                    var request = URLRequest(url: url)
                    request.httpMethod = method
                    request.httpBody = body
                    request.timeoutInterval = configuration.streamTimeoutInterval
                    applyStandardHeaders(to: &request, hasBody: true)

                    let (dataStream, response) = try await NetworkingSupport.enhancedStreamTask(
                        session: session,
                        for: request,
                        configuration: configuration
                    )

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OllamaError.invalidResponse
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        var errorBody = Data()
                        do {
                            for try await chunk in dataStream {
                                errorBody.append(chunk)
                                if errorBody.count > 8192 { break }
                            }
                        } catch {
                        }
                        throw OllamaError.fromServer(
                            statusCode: httpResponse.statusCode,
                            body: errorBody,
                            retryAfter: Self.retryAfterSeconds(from: httpResponse)
                        ) ?? OllamaError.unexpectedStatusCode(httpResponse.statusCode)
                    }

                    var buffer = Data()
                    let newline = UInt8(ascii: "\n")

                    for try await chunk in dataStream {
                        buffer.append(chunk)

                        while let newlineIndex = buffer.firstIndex(of: newline) {
                            let lineData = buffer[..<newlineIndex]
                            buffer.removeSubrange(...newlineIndex)
                            try Self.decodeStreamLine(
                                lineData,
                                decoder: decoder,
                                into: continuation
                            )
                        }
                    }

                    if !buffer.isEmpty {
                        try Self.decodeStreamLine(buffer, decoder: decoder, into: continuation)
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

    /// Decodes one NDJSON line, surfacing an in-band `{"error": ...}` line as a thrown error.
    ///
    /// Ollama can report a mid-stream failure by emitting a line of the form `{"error": "message"}`
    /// instead of a normal response object. Decoding that straight into `T` would surface a confusing
    /// ``OllamaError/decodingError(_:)``; this checks for the error field first and throws the real
    /// ``OllamaError/serverError(_:)``.
    private static func decodeStreamLine<T: Decodable & Sendable>(
        _ line: Data,
        decoder: JSONDecoder,
        into continuation: AsyncThrowingStream<T, Error>.Continuation
    ) throws {
        if line.isEmpty { return }
        if let streamError = try? decoder.decode(StreamErrorLine.self, from: line),
            !streamError.error.isEmpty
        {
            throw OllamaError.serverError(streamError.error)
        }
        do {
            continuation.yield(try decoder.decode(T.self, from: line))
        } catch {
            throw OllamaError.decodingError(error)
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
            throw OllamaError.invalidParameters(
                "Failed to encode request: \(error.localizedDescription)"
            )
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

/// An in-band error line emitted mid-stream by Ollama, e.g. `{"error": "model not found"}`.
private struct StreamErrorLine: Decodable {
    let error: String
}
