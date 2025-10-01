import Foundation

/// Response from a text generation request.
///
/// Contains the model's text response along with metadata about the generation process.
/// Streamed responses yield multiple instances, with `done` set to `true` on the final chunk.
public struct GenerateResponse: Codable, Sendable {
    /// The model that generated the response.
    public let model: String

    /// Timestamp when the response was created.
    public let createdAt: Date

    /// The generated text content.
    public let response: String

    /// Whether this is the final chunk in a streamed response.
    public let done: Bool

    /// Reason for completion (e.g., "stop", "length"). Only present when `done` is `true`.
    public let doneReason: String?

    /// Conversation context for continuing multi-turn interactions. Only present when `done` is `true`.
    public let context: [Int]?

    /// Total time taken for the request in nanoseconds. Only present when `done` is `true`.
    public let totalDuration: UInt64?

    /// Time taken to load the model in nanoseconds. Only present when `done` is `true`.
    public let loadDuration: UInt64?

    /// Number of tokens in the prompt. Only present when `done` is `true`.
    public let promptEvalCount: Int?

    /// Time taken to process the prompt in nanoseconds. Only present when `done` is `true`.
    public let promptEvalDuration: UInt64?

    /// Number of tokens generated in the response. Only present when `done` is `true`.
    public let evalCount: Int?

    /// Time taken to generate the response in nanoseconds. Only present when `done` is `true`.
    public let evalDuration: UInt64?

    private enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
        case doneReason = "done_reason"
        case context
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        model = try container.decode(String.self, forKey: .model)
        response = try container.decode(String.self, forKey: .response)
        done = try container.decode(Bool.self, forKey: .done)
        doneReason = try container.decodeIfPresent(String.self, forKey: .doneReason)
        context = try container.decodeIfPresent([Int].self, forKey: .context)
        totalDuration = try container.decodeIfPresent(UInt64.self, forKey: .totalDuration)
        loadDuration = try container.decodeIfPresent(UInt64.self, forKey: .loadDuration)
        promptEvalCount = try container.decodeIfPresent(Int.self, forKey: .promptEvalCount)
        promptEvalDuration = try container.decodeIfPresent(UInt64.self, forKey: .promptEvalDuration)
        evalCount = try container.decodeIfPresent(Int.self, forKey: .evalCount)
        evalDuration = try container.decodeIfPresent(UInt64.self, forKey: .evalDuration)

        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath + [CodingKeys.createdAt],
                        debugDescription:
                            "Date string '\(dateString)' does not match expected format",
                        underlyingError: nil
                    )
                )
            }
        }
    }
}
