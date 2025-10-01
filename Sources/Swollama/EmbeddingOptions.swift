import Foundation

/// Options for configuring embedding generation requests.
///
/// Controls embedding behavior including input truncation, model parameters, and
/// model keep-alive duration.
public struct EmbeddingOptions {
    /// Whether to truncate input text that exceeds the model's maximum context length. Defaults to `true`.
    public let truncate: Bool?

    /// Model-specific parameters (most embedding models have limited parameter support).
    public let modelOptions: ModelOptions?

    /// How long to keep the model loaded in memory (in seconds). Overrides the client's default.
    public let keepAlive: TimeInterval?

    /// Creates embedding options with the specified settings.
    ///
    /// - Parameters:
    ///   - truncate: Whether to truncate long inputs. Defaults to `true`.
    ///   - modelOptions: Model-specific parameters.
    ///   - keepAlive: Model keep-alive duration in seconds.
    public init(
        truncate: Bool? = true,
        modelOptions: ModelOptions? = nil,
        keepAlive: TimeInterval? = nil
    ) {
        self.truncate = truncate
        self.modelOptions = modelOptions
        self.keepAlive = keepAlive
    }

    /// Default embedding options with truncation enabled.
    public static let `default` = EmbeddingOptions()
}
