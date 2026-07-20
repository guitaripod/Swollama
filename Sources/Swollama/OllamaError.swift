import Foundation

/// Errors that can occur when interacting with the Ollama API.
///
/// All ``OllamaClient`` methods can throw errors of this type. Each case provides
/// specific information about what went wrong, making it easier to handle different
/// error scenarios appropriately.
public enum OllamaError: LocalizedError {
    /// The server returned a response that could not be parsed or understood.
    case invalidResponse

    /// Failed to decode the server response into the expected Swift types.
    ///
    /// Contains the underlying decoding error for debugging.
    case decodingError(Error)

    /// The Ollama server returned an error response.
    ///
    /// Contains the error message from the server.
    case serverError(String)

    /// The requested model was not found on the server.
    case modelNotFound

    /// The operation was cancelled before completion.
    case cancelled

    /// A network error occurred while communicating with the server.
    ///
    /// Contains the underlying network error for debugging.
    case networkError(Error)

    /// The server returned an unexpected HTTP status code.
    ///
    /// Contains the status code that was received.
    case unexpectedStatusCode(Int)

    /// Authentication failed (HTTP 401 or 403).
    ///
    /// Set an ``OllamaConfiguration/apiKey`` to authenticate. Contains the server's message, if any.
    case authenticationFailed(String?)

    /// The server is rate limiting requests (HTTP 429).
    ///
    /// `retryAfter` carries the server's `Retry-After` hint in seconds, when provided.
    case rateLimited(retryAfter: TimeInterval?)

    /// An HTTP error occurred during a web request.
    ///
    /// Contains the HTTP status code and optional error message.
    case httpError(statusCode: Int, message: String? = nil)

    /// The request parameters were invalid or malformed.
    ///
    /// Contains a description of what was invalid.
    case invalidParameters(String)

    /// A file operation failed (reading, writing, or accessing files).
    ///
    /// Contains a description of the file error.
    case fileError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .modelNotFound:
            return "The requested model was not found"
        case .cancelled:
            return "The operation was cancelled"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        case .authenticationFailed(let message):
            if let message = message, !message.isEmpty {
                return "Authentication failed: \(message)"
            }
            return "Authentication failed. Set an API key in OllamaConfiguration to authenticate."
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limited. Retry after \(Int(retryAfter))s."
            }
            return "Rate limited by the server."
        case .httpError(let statusCode, let message):
            if let message = message {
                return "HTTP error \(statusCode): \(message)"
            }
            return "HTTP error \(statusCode)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .fileError(let message):
            return "File error: \(message)"
        }
    }

    /// Maps an HTTP status code and response body to the most specific ``OllamaError``.
    ///
    /// Ollama returns errors as a JSON object of the form `{"error": "message"}`. This decodes that
    /// message when present and falls back to the raw body otherwise, so callers see the server's
    /// explanation rather than an opaque status code.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code returned by the server.
    ///   - body: The raw response body, if any.
    ///   - retryAfter: The parsed `Retry-After` header value in seconds, for `429` responses.
    /// - Returns: The corresponding error, or `nil` for a success (`2xx`) status.
    public static func fromServer(
        statusCode: Int,
        body: Data?,
        retryAfter: TimeInterval? = nil
    ) -> OllamaError? {
        if (200...299).contains(statusCode) { return nil }

        let message = extractMessage(from: body)

        switch statusCode {
        case 401, 403:
            return .authenticationFailed(message)
        case 404:
            return .modelNotFound
        case 429:
            return .rateLimited(retryAfter: retryAfter)
        case 400...499:
            return .invalidParameters(message ?? "Unknown error")
        case 500...599:
            return .serverError(message ?? "Unknown server error")
        default:
            return .unexpectedStatusCode(statusCode)
        }
    }

    /// Extracts the human-readable message from an Ollama error body.
    ///
    /// Prefers the `error` field of a `{"error": ...}` object and falls back to the raw UTF-8 body.
    static func extractMessage(from body: Data?) -> String? {
        guard let body = body, !body.isEmpty else { return nil }
        if let decoded = try? JSONDecoder().decode(ServerErrorBody.self, from: body),
            !decoded.error.isEmpty
        {
            return decoded.error
        }
        let raw = String(data: body, encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return (raw?.isEmpty == false) ? raw : nil
    }

    private struct ServerErrorBody: Decodable {
        let error: String
    }
}
