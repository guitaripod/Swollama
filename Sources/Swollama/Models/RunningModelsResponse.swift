import Foundation


struct RunningModelsResponse: Codable {
    let models: [RunningModelInfo]
}


public struct RunningModelInfo: Codable, Sendable {

    public let name: String

    public let model: String

    public let size: UInt64

    public let digest: String

    public let details: ModelDetails

    public let expiresAt: Date

    public let sizeVRAM: UInt64

    private enum CodingKeys: String, CodingKey {
        case name, model, size, digest, details
        case expiresAt = "expires_at"
        case sizeVRAM = "size_vram"
    }
}
