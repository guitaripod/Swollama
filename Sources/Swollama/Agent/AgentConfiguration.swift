import Foundation

/// Configuration settings for agent behavior and capabilities.
///
/// Controls how the agent operates during autonomous workflows, including iteration limits,
/// result truncation, thinking mode, and model parameters.
///
/// ## Overview
///
/// The configuration allows you to balance between thoroughness and speed:
/// - ``default``: Balanced settings suitable for most use cases
/// - ``extended``: More iterations and larger context for complex tasks
/// - ``fast``: Fewer iterations and disabled thinking for quick answers
///
/// ## Example
///
/// ```swift
/// let config = AgentConfiguration(
///     maxIterations: 15,
///     truncateResults: 10000,
///     enableThinking: true,
///     modelOptions: ModelOptions(temperature: 0.3)
/// )
///
/// let agent = OllamaAgent(webSearchAPIKey: apiKey, configuration: config)
/// ```
public struct AgentConfiguration: Sendable {
    /// Maximum number of tool-calling iterations before the agent stops.
    ///
    /// Prevents infinite loops while allowing the agent to perform multiple tool calls.
    public let maxIterations: Int

    /// Maximum character length for tool results before truncation.
    ///
    /// Set to `nil` to disable truncation. Truncation helps manage context window size.
    public let truncateResults: Int?

    /// Whether to enable extended thinking mode for reasoning models.
    ///
    /// When enabled, the model shows its reasoning process through ``AgentEvent/thinking(_:)`` events.
    public let enableThinking: Bool

    /// Model-specific parameters to use for all chat requests.
    ///
    /// See ``ModelOptions`` for available settings like temperature, context size, etc.
    public let modelOptions: ModelOptions?

    /// Creates an agent configuration with custom settings.
    ///
    /// - Parameters:
    ///   - maxIterations: Maximum tool-calling iterations (default: 10).
    ///   - truncateResults: Maximum characters for tool results, or `nil` for no limit (default: 8000).
    ///   - enableThinking: Enable extended thinking mode (default: true).
    ///   - modelOptions: Optional model-specific parameters.
    public init(
        maxIterations: Int = 10,
        truncateResults: Int? = 8000,
        enableThinking: Bool = true,
        modelOptions: ModelOptions? = nil
    ) {
        self.maxIterations = maxIterations
        self.truncateResults = truncateResults
        self.enableThinking = enableThinking
        self.modelOptions = modelOptions
    }

    /// Default configuration with balanced settings.
    ///
    /// - Max iterations: 10
    /// - Truncate results: 8000 characters
    /// - Thinking enabled: Yes
    /// - Model options: None
    public static let `default` = AgentConfiguration()

    /// Extended configuration for complex, multi-step tasks.
    ///
    /// - Max iterations: 20
    /// - Truncate results: 16000 characters
    /// - Thinking enabled: Yes
    /// - Model options: Large context window (32000)
    public static let extended = AgentConfiguration(
        maxIterations: 20,
        truncateResults: 16000,
        enableThinking: true,
        modelOptions: ModelOptions(numCtx: 32000)
    )

    /// Fast configuration for quick, simple queries.
    ///
    /// - Max iterations: 5
    /// - Truncate results: 4000 characters
    /// - Thinking enabled: No
    /// - Model options: Low temperature (0.0) for deterministic responses
    public static let fast = AgentConfiguration(
        maxIterations: 5,
        truncateResults: 4000,
        enableThinking: false,
        modelOptions: ModelOptions(temperature: 0.0)
    )
}
