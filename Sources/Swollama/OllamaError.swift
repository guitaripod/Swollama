import Foundation


public enum OllamaError: LocalizedError {

    case invalidResponse


    case decodingError(Error)


    case serverError(String)


    case modelNotFound


    case cancelled


    case networkError(Error)


    case unexpectedStatusCode(Int)


    case invalidParameters(String)


    case fileError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server returned an invalid response"
        case .decodingError(let error): "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message): "Server error: \(message)"
        case .modelNotFound: "The requested model was not found"
        case .cancelled: "The operation was cancelled"
        case .networkError(let error): "Network error: \(error.localizedDescription)"
        case .unexpectedStatusCode(let code): "Unexpected status code: \(code)"
        case .invalidParameters(let message): "Invalid parameters: \(message)"
        case .fileError(let message): "File error: \(message)"
        }
    }
}
