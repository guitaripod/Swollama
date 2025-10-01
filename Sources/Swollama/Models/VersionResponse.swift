import Foundation


public struct VersionResponse: Codable, Sendable {

    public let version: String

    public init(version: String) {
        self.version = version
    }
}