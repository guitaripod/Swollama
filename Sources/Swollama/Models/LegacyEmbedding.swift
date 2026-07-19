import Foundation

/// Request body for the legacy `POST /api/embeddings` endpoint.
struct LegacyEmbeddingRequest: Codable, Sendable {
    let model: String
    let prompt: String
    let options: ModelOptions?
    let keepAlive: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case model, prompt, options
        case keepAlive = "keep_alive"
    }
}

/// Response from the legacy `POST /api/embeddings` endpoint.
///
/// Returns a single embedding vector for one prompt. Prefer
/// ``EmbeddingResponse`` (via ``OllamaClient/generateEmbeddings(input:model:options:)``), which
/// batches inputs and reports timing metadata.
public struct LegacyEmbeddingResponse: Codable, Sendable {
    /// The embedding vector for the prompt.
    public let embedding: [Double]

    public init(embedding: [Double]) {
        self.embedding = embedding
    }
}
