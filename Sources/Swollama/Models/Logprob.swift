import Foundation

/// Per-token log-probability information, returned when `logprobs` is requested.
///
/// Each `Logprob` describes a single generated token: the token text, its log-probability, its raw
/// UTF-8 bytes, and — when `top_logprobs` is requested — the most likely alternative tokens at that
/// position.
public struct Logprob: Codable, Sendable {
    /// The generated token text.
    public let token: String

    /// The natural-log probability of the token.
    public let logprob: Double

    /// The token's raw UTF-8 bytes, when provided.
    public let bytes: [Int]?

    /// The most likely alternative tokens at this position, when `top_logprobs` was requested.
    public let topLogprobs: [TopLogprob]?

    private enum CodingKeys: String, CodingKey {
        case token, logprob, bytes
        case topLogprobs = "top_logprobs"
    }

    public init(
        token: String,
        logprob: Double,
        bytes: [Int]? = nil,
        topLogprobs: [TopLogprob]? = nil
    ) {
        self.token = token
        self.logprob = logprob
        self.bytes = bytes
        self.topLogprobs = topLogprobs
    }
}

/// A candidate alternative token and its log-probability at a single position.
public struct TopLogprob: Codable, Sendable {
    /// The candidate token text.
    public let token: String

    /// The natural-log probability of the candidate token.
    public let logprob: Double

    /// The candidate token's raw UTF-8 bytes, when provided.
    public let bytes: [Int]?

    public init(token: String, logprob: Double, bytes: [Int]? = nil) {
        self.token = token
        self.logprob = logprob
        self.bytes = bytes
    }
}
