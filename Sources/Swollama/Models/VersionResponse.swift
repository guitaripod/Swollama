import Foundation

/// Response from the version endpoint
public struct VersionResponse: Codable, Sendable {
    /// The Ollama server version
    public let version: String
    
    public init(version: String) {
        self.version = version
    }
}