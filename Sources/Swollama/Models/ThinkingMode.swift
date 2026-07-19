import Foundation

/// Controls whether — and how hard — a reasoning-capable model "thinks" before answering.
///
/// The Ollama `think` parameter accepts either a boolean (enable/disable thinking) or, for models
/// that support reasoning-effort levels (such as gpt-oss), a string like `"low"`, `"medium"`, or
/// `"high"`. `ThinkingMode` models both forms and encodes to the appropriate JSON value.
///
/// A boolean literal is accepted directly, so existing call sites keep working:
///
/// ```swift
/// let options = ChatOptions(think: true)          // enable thinking
/// let options = ChatOptions(think: .high)         // reasoning-effort level
/// let options = ChatOptions(think: .level("max")) // any server-supported level
/// ```
public enum ThinkingMode: Codable, Sendable, Hashable, ExpressibleByBooleanLiteral {
    /// Enable thinking (`true`).
    case enabled
    /// Disable thinking (`false`).
    case disabled
    /// Enable thinking at a named reasoning-effort level (e.g. `"low"`, `"medium"`, `"high"`).
    case level(String)

    /// Low reasoning effort.
    public static let low = ThinkingMode.level("low")
    /// Medium reasoning effort.
    public static let medium = ThinkingMode.level("medium")
    /// High reasoning effort.
    public static let high = ThinkingMode.level("high")
    /// Maximum reasoning effort (server may map this to `high` for some models).
    public static let max = ThinkingMode.level("max")

    public init(booleanLiteral value: Bool) {
        self = value ? .enabled : .disabled
    }

    /// Creates a mode from a boolean: `true` enables thinking, `false` disables it.
    public init(_ enabled: Bool) {
        self = enabled ? .enabled : .disabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = boolValue ? .enabled : .disabled
        } else if let stringValue = try? container.decode(String.self) {
            self = .level(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "`think` must be a boolean or a reasoning-effort level string"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enabled:
            try container.encode(true)
        case .disabled:
            try container.encode(false)
        case .level(let value):
            try container.encode(value)
        }
    }
}
