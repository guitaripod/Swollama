import Foundation

/// Response containing the Ollama server version.
public struct VersionResponse: Codable, Sendable {
    /// The Ollama server version string.
    public let version: String

    public init(version: String) {
        self.version = version
    }
}
