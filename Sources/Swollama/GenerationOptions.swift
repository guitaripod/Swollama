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

    /// Whether to enable extended thinking mode for reasoning models.
    public let think: Bool?

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
        think: Bool? = nil
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
    }

    /// Default generation options with no constraints.
    public static let `default` = GenerationOptions()
}
