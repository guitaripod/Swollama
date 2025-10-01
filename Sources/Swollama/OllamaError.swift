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
}
