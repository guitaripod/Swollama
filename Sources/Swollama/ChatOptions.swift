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

    /// Whether to enable extended thinking mode for reasoning models.
    public let think: Bool?

    /// Creates chat options with the specified settings.
    ///
    /// - Parameters:
    ///   - tools: Tool definitions for function calling.
    ///   - format: Response format constraint.
    ///   - modelOptions: Model-specific parameters.
    ///   - keepAlive: Model keep-alive duration in seconds.
    ///   - think: Enable extended thinking mode.
    public init(
        tools: [ToolDefinition]? = nil,
        format: ResponseFormat? = nil,
        modelOptions: ModelOptions? = nil,
        keepAlive: TimeInterval? = nil,
        think: Bool? = nil
    ) {
        self.tools = tools
        self.format = format
        self.modelOptions = modelOptions
        self.keepAlive = keepAlive
        self.think = think
    }

    /// Default chat options with no constraints.
    public static let `default` = ChatOptions()
}
