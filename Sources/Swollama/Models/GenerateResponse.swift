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

    /// The model's reasoning/thinking content, when `think` is enabled for a reasoning-capable model.
    public let thinking: String?

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

    /// Tool calls emitted by the model, when the prompt provided tools and the model invoked them.
    public let toolCalls: [ToolCall]?

    /// Per-token log-probabilities, when `logprobs` was requested.
    public let logprobs: [Logprob]?

    /// Base64-encoded output image (image-generation models only).
    public let image: String?

    /// Progress numerator for image generation (diffusion steps completed).
    public let completed: UInt64?

    /// Progress denominator for image generation (total diffusion steps).
    public let total: UInt64?

    /// The upstream cloud model name, when this response was proxied to a remote model.
    public let remoteModel: String?

    /// The upstream cloud host, when this response was proxied to a remote model.
    public let remoteHost: String?

    private enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case thinking
        case done
        case doneReason = "done_reason"
        case context
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
        case toolCalls = "tool_calls"
        case logprobs
        case image, completed, total
        case remoteModel = "remote_model"
        case remoteHost = "remote_host"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        model = try container.decode(String.self, forKey: .model)
        response = try container.decode(String.self, forKey: .response)
        thinking = try container.decodeIfPresent(String.self, forKey: .thinking)
        done = try container.decode(Bool.self, forKey: .done)
        doneReason = try container.decodeIfPresent(String.self, forKey: .doneReason)
        context = try container.decodeIfPresent([Int].self, forKey: .context)
        totalDuration = try container.decodeIfPresent(UInt64.self, forKey: .totalDuration)
        loadDuration = try container.decodeIfPresent(UInt64.self, forKey: .loadDuration)
        promptEvalCount = try container.decodeIfPresent(Int.self, forKey: .promptEvalCount)
        promptEvalDuration = try container.decodeIfPresent(UInt64.self, forKey: .promptEvalDuration)
        evalCount = try container.decodeIfPresent(Int.self, forKey: .evalCount)
        evalDuration = try container.decodeIfPresent(UInt64.self, forKey: .evalDuration)
        toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
        logprobs = try container.decodeIfPresent([Logprob].self, forKey: .logprobs)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        completed = try container.decodeIfPresent(UInt64.self, forKey: .completed)
        total = try container.decodeIfPresent(UInt64.self, forKey: .total)
        remoteModel = try container.decodeIfPresent(String.self, forKey: .remoteModel)
        remoteHost = try container.decodeIfPresent(String.self, forKey: .remoteHost)

        createdAt = try OllamaDate.decode(from: container, forKey: .createdAt)
    }
}
