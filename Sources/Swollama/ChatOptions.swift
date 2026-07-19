import Foundation

/// Options for configuring chat completion requests.
///
/// Provides fine-grained control over chat behavior including tool usage, output formatting,
/// model parameters, and extended thinking modes.
///
/// ## Example
///
/// ```swift
/// let options = ChatOptions(
///     format: .json,
///     modelOptions: ModelOptions(temperature: 0.7, numPredict: 100),
///     keepAlive: 600
/// )
/// ```
public struct ChatOptions {
    /// Tool definitions to make available to the model for function calling.
    public let tools: [ToolDefinition]?

    /// Response format constraint, either `.json` for unstructured JSON or `.jsonSchema(_:)` for structured output.
    public let format: ResponseFormat?

    /// Model-specific parameters like temperature, top_p, etc.
    public let modelOptions: ModelOptions?

    /// How long to keep the model loaded in memory (in seconds). Overrides the client's default.
    public let keepAlive: TimeInterval?

    /// Whether — and how hard — to enable thinking for reasoning-capable models.
    public let think: ThinkingMode?

    /// Whether to return per-token log-probabilities.
    public let logprobs: Bool?

    /// Number of top alternative tokens to return per position (0–20). Requires `logprobs`.
    public let topLogprobs: Int?

    /// Whether to trim the oldest history when the prompt exceeds the context window. Defaults to `true`.
    public let truncate: Bool?

    /// Whether to slide the context window when the prompt overflows, instead of erroring. Defaults to `true`.
    public let shift: Bool?

    /// Creates chat options with the specified settings.
    ///
    /// - Parameters:
    ///   - tools: Tool definitions for function calling.
    ///   - format: Response format constraint.
    ///   - modelOptions: Model-specific parameters.
    ///   - keepAlive: Model keep-alive duration in seconds.
    ///   - think: Enable extended thinking mode.
    ///   - logprobs: Return per-token log-probabilities.
    ///   - topLogprobs: Number of top alternative tokens per position (requires `logprobs`).
    ///   - truncate: Trim oldest history when the prompt exceeds the context window.
    ///   - shift: Slide the context window on overflow instead of erroring.
    public init(
        tools: [ToolDefinition]? = nil,
        format: ResponseFormat? = nil,
        modelOptions: ModelOptions? = nil,
        keepAlive: TimeInterval? = nil,
        think: ThinkingMode? = nil,
        logprobs: Bool? = nil,
        topLogprobs: Int? = nil,
        truncate: Bool? = nil,
        shift: Bool? = nil
    ) {
        self.tools = tools
        self.format = format
        self.modelOptions = modelOptions
        self.keepAlive = keepAlive
        self.think = think
        self.logprobs = logprobs
        self.topLogprobs = topLogprobs
        self.truncate = truncate
        self.shift = shift
    }

    /// Default chat options with no constraints.
    public static let `default` = ChatOptions()
}
