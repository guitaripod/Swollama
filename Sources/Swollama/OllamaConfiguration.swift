import Foundation

/// Configuration settings for ``OllamaClient``.
///
/// Controls client behavior including network timeouts, retry logic, and model keep-alive duration.
/// Use ``OllamaConfiguration/default`` for standard settings or create a custom configuration
/// for specific requirements.
///
/// ## Example
///
/// ```swift
/// let config = OllamaConfiguration(
///     timeoutInterval: 60,
///     maxRetries: 5,
///     retryDelay: 2,
///     defaultKeepAlive: 600
/// )
/// let client = OllamaClient(configuration: config)
/// ```
public struct OllamaConfiguration: Sendable {
    /// Timeout for individual (non-streaming) HTTP requests in seconds. Defaults to 30 seconds.
    ///
    /// Streaming requests (generation, chat, pull, push) are not bound by this value; they use
    /// ``streamTimeoutInterval`` so long-running generations and cold model loads are not aborted.
    public let timeoutInterval: TimeInterval

    /// Idle timeout for streaming requests in seconds. Defaults to 300 seconds (5 minutes).
    ///
    /// This bounds how long a streaming request will wait for the *next* chunk of data (for example,
    /// while a large model is loading before the first token). It is not a cap on total duration, so
    /// long generations complete normally.
    public let streamTimeoutInterval: TimeInterval

    /// Maximum number of retry attempts for failed requests. Defaults to 3.
    public let maxRetries: Int

    /// Delay between retry attempts in seconds. Defaults to 1 second.
    public let retryDelay: TimeInterval

    /// Whether to allow insecure HTTPS connections (self-signed certificates). Defaults to `false`.
    public let allowsInsecureConnections: Bool

    /// Optional API key sent as an `Authorization: Bearer <key>` header on every request.
    ///
    /// Set this to reach an authenticated Ollama host (for example, a deployment behind an auth
    /// proxy, or Ollama's cloud API). Defaults to `nil` (no `Authorization` header is sent).
    public let apiKey: String?

    /// Default keep-alive duration for models in seconds. Defaults to 300 seconds (5 minutes).
    ///
    /// Models remain loaded in memory for this duration after their last use. Set to 0 to unload
    /// immediately, or -1 to keep loaded indefinitely.
    public let defaultKeepAlive: TimeInterval

    /// Creates a new configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - timeoutInterval: Timeout for non-streaming HTTP requests in seconds. Defaults to 30.
    ///   - streamTimeoutInterval: Idle timeout for streaming requests in seconds. Defaults to 300.
    ///   - maxRetries: Maximum retry attempts. Defaults to 3.
    ///   - retryDelay: Delay between retries in seconds. Defaults to 1.
    ///   - allowsInsecureConnections: Allow insecure HTTPS connections. Defaults to `false`.
    ///   - apiKey: Optional bearer token sent as an `Authorization` header. Defaults to `nil`.
    ///   - defaultKeepAlive: Default model keep-alive duration in seconds. Defaults to 300.
    public init(
        timeoutInterval: TimeInterval = 30,
        streamTimeoutInterval: TimeInterval = 300,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1,
        allowsInsecureConnections: Bool = false,
        apiKey: String? = nil,
        defaultKeepAlive: TimeInterval = 300
    ) {
        self.timeoutInterval = timeoutInterval
        self.streamTimeoutInterval = streamTimeoutInterval
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.allowsInsecureConnections = allowsInsecureConnections
        self.apiKey = apiKey
        self.defaultKeepAlive = defaultKeepAlive
    }

    /// Default configuration with standard settings.
    public static let `default` = OllamaConfiguration()
}
