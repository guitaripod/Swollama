import Foundation


public struct EmbeddingResponse: Codable, Sendable {

    public let model: String

    public let embeddings: [[Double]]

    public let totalDuration: UInt64?

    public let loadDuration: UInt64?

    public let promptEvalCount: Int?

    private enum CodingKeys: String, CodingKey {
        case model
        case embeddings
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
    }
}
