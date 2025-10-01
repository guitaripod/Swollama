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
public struct OllamaConfiguration {
    /// Timeout for individual HTTP requests in seconds. Defaults to 30 seconds.
    public let timeoutInterval: TimeInterval

    /// Maximum number of retry attempts for failed requests. Defaults to 3.
    public let maxRetries: Int

    /// Delay between retry attempts in seconds. Defaults to 1 second.
    public let retryDelay: TimeInterval

    /// Whether to allow insecure HTTPS connections (self-signed certificates). Defaults to `false`.
    public let allowsInsecureConnections: Bool

    /// Default keep-alive duration for models in seconds. Defaults to 300 seconds (5 minutes).
    ///
    /// Models remain loaded in memory for this duration after their last use. Set to 0 to unload
    /// immediately, or -1 to keep loaded indefinitely.
    public let defaultKeepAlive: TimeInterval

    /// Creates a new configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - timeoutInterval: Timeout for HTTP requests in seconds. Defaults to 30.
    ///   - maxRetries: Maximum retry attempts. Defaults to 3.
    ///   - retryDelay: Delay between retries in seconds. Defaults to 1.
    ///   - allowsInsecureConnections: Allow insecure HTTPS connections. Defaults to `false`.
    ///   - defaultKeepAlive: Default model keep-alive duration in seconds. Defaults to 300.
    public init(
        timeoutInterval: TimeInterval = 30,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1,
        allowsInsecureConnections: Bool = false,
        defaultKeepAlive: TimeInterval = 300
    ) {
        self.timeoutInterval = timeoutInterval
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.allowsInsecureConnections = allowsInsecureConnections
        self.defaultKeepAlive = defaultKeepAlive
    }

    /// Default configuration with standard settings.
    public static let `default` = OllamaConfiguration()
}
