import Foundation

/// Options for configuring text generation requests.
///
/// Provides comprehensive control over generation behavior including multimodal inputs,
/// output formatting, system prompts, and conversation context.
public struct GenerationOptions {
    /// Text to append after the model's generated response (for fill-in-the-middle scenarios).
    public let suffix: String?

    /// Base64-encoded images to include with the prompt for multimodal models.
    public let images: [String]?

    /// Response format constraint, either `.json` for unstructured JSON or `.jsonSchema(_:)` for structured output.
    public let format: ResponseFormat?

    /// Model-specific parameters like temperature, top_p, etc.
    public let modelOptions: ModelOptions?

    /// System prompt to set model behavior and context.
    public let systemPrompt: String?

    /// Custom prompt template to override the model's default template.
    public let template: String?

    /// Conversation context from a previous generation to continue the conversation.
    public let context: [Int]?

    /// Whether to bypass prompt template processing and send the raw prompt directly.
    public let raw: Bool?

    /// How long to keep the model loaded in memory (in seconds). Overrides the client's default.
    public let keepAlive: TimeInterval?

    /// Whether — and how hard — to enable thinking for reasoning-capable models.
    public let think: ThinkingMode?

    /// Whether to return per-token log-probabilities.
    public let logprobs: Bool?

    /// Number of top alternative tokens to return per position (0–20). Requires `logprobs`.
    public let topLogprobs: Int?

    /// Whether to truncate the prompt to fit the context window. Defaults to `true` server-side.
    public let truncate: Bool?

    /// Whether to shift the context window when the prompt overflows, instead of erroring.
    public let shift: Bool?

    /// Output image width in pixels (image-generation models only).
    public let width: Int?

    /// Output image height in pixels (image-generation models only).
    public let height: Int?

    /// Number of diffusion steps (image-generation models only).
    public let steps: Int?

    /// Creates generation options with the specified settings.
    ///
    /// - Parameters:
    ///   - suffix: Text to append after generation.
    ///   - images: Base64-encoded images for multimodal input.
    ///   - format: Response format constraint.
    ///   - modelOptions: Model-specific parameters.
    ///   - systemPrompt: System prompt for model behavior.
    ///   - template: Custom prompt template.
    ///   - context: Conversation context from previous generation.
    ///   - raw: Bypass prompt template processing.
    ///   - keepAlive: Model keep-alive duration in seconds.
    ///   - think: Enable extended thinking mode.
    ///   - logprobs: Return per-token log-probabilities.
    ///   - topLogprobs: Number of top alternative tokens per position (requires `logprobs`).
    ///   - truncate: Truncate the prompt to fit the context window.
    ///   - shift: Shift the context window on overflow instead of erroring.
    ///   - width: Output image width (image-generation models only).
    ///   - height: Output image height (image-generation models only).
    ///   - steps: Diffusion steps (image-generation models only).
    public init(
        suffix: String? = nil,
        images: [String]? = nil,
        format: ResponseFormat? = nil,
        modelOptions: ModelOptions? = nil,
        systemPrompt: String? = nil,
        template: String? = nil,
        context: [Int]? = nil,
        raw: Bool? = nil,
        keepAlive: TimeInterval? = nil,
        think: ThinkingMode? = nil,
        logprobs: Bool? = nil,
        topLogprobs: Int? = nil,
        truncate: Bool? = nil,
        shift: Bool? = nil,
        width: Int? = nil,
        height: Int? = nil,
        steps: Int? = nil
    ) {
        self.suffix = suffix
        self.images = images
        self.format = format
        self.modelOptions = modelOptions
        self.systemPrompt = systemPrompt
        self.template = template
        self.context = context
        self.raw = raw
        self.keepAlive = keepAlive
        self.think = think
        self.logprobs = logprobs
        self.topLogprobs = topLogprobs
        self.truncate = truncate
        self.shift = shift
        self.width = width
        self.height = height
        self.steps = steps
    }

    /// Default generation options with no constraints.
    public static let `default` = GenerationOptions()
}
