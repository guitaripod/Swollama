import Foundation



public struct ChatResponse: Codable, Sendable {

    public let model: String


    public let createdAt: Date


    public let message: ChatMessage


    public let done: Bool


    public let totalDuration: UInt64?


    public let loadDuration: UInt64?


    public let promptEvalCount: Int?


    public let promptEvalDuration: UInt64?


    public let evalCount: Int?


    public let evalDuration: UInt64?


    private enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
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
        message = try container.decode(ChatMessage.self, forKey: .message)
        done = try container.decode(Bool.self, forKey: .done)
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
                        debugDescription: "Date string '\(dateString)' does not match expected format",
                        underlyingError: nil
                    )
                )
            }
        }
    }
}
