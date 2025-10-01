import Foundation

/// Response from an embedding generation request.
///
/// Contains the generated vector embeddings along with performance metrics.
public struct EmbeddingResponse: Codable, Sendable {
    /// The embedding model that generated the vectors.
    public let model: String

    /// The generated embeddings. Each array is a vector representation of an input string.
    public let embeddings: [[Double]]

    /// Total time taken for the request in nanoseconds.
    public let totalDuration: UInt64?

    /// Time taken to load the model in nanoseconds.
    public let loadDuration: UInt64?

    /// Number of tokens processed.
    public let promptEvalCount: Int?

    private enum CodingKeys: String, CodingKey {
        case model
        case embeddings
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
    }
}
