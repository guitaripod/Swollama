import Foundation

/// Robust parser for the RFC 3339 / ISO 8601 timestamps returned by the Ollama API.
///
/// Ollama emits timestamps with a variable number of fractional-second digits (Go's `time.Time`
/// prints up to nanosecond precision, e.g. `2026-04-11T13:53:18.632244808+03:00`) and either a
/// numeric UTC offset (`+03:00`) or `Z`. `Foundation.ISO8601DateFormatter` only reliably accepts
/// millisecond precision, so fractional seconds are normalized to three digits before parsing.
enum OllamaDate {
    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plainFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalRegex = try? NSRegularExpression(pattern: "\\.(\\d+)")

    /// `ISO8601DateFormatter` is a reference type with mutable internal parsing state, so the shared
    /// instances above are guarded to remain safe when multiple clients decode concurrently.
    private static let lock = NSLock()

    /// Parses an Ollama timestamp string into a `Date`, or returns `nil` if it cannot be parsed.
    static func parse(_ string: String) -> Date? {
        let normalized = normalizeFractionalSeconds(string)
        lock.lock()
        defer { lock.unlock() }
        if let date = fractionalFormatter.date(from: normalized) { return date }
        if let date = plainFormatter.date(from: normalized) { return date }
        if let date = fractionalFormatter.date(from: string) { return date }
        if let date = plainFormatter.date(from: string) { return date }
        return nil
    }

    /// Decodes a `Date` from a keyed container, throwing a descriptive error on failure.
    static func decode<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) throws -> Date {
        let string = try container.decode(String.self, forKey: key)
        guard let date = parse(string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [key],
                    debugDescription: "Timestamp '\(string)' is not a valid RFC 3339 date"
                )
            )
        }
        return date
    }

    private static func normalizeFractionalSeconds(_ string: String) -> String {
        guard let regex = fractionalRegex else { return string }
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: range),
            let digitsRange = Range(match.range(at: 1), in: string)
        else {
            return string
        }

        let digits = String(string[digitsRange])
        let millis = String((digits + "000").prefix(3))
        guard let fullRange = Range(match.range, in: string) else { return string }
        return string.replacingCharacters(in: fullRange, with: ".\(millis)")
    }
}
