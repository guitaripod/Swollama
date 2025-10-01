import Foundation


struct RunningModelsResponse: Codable {
    let models: [RunningModelInfo]
}


/// Information about a currently running model.
///
/// Represents a model that is currently loaded in memory.
public struct RunningModelInfo: Codable, Sendable {
    /// The model's name in full format (e.g., "llama3.2:latest").
    public let name: String

    /// The model identifier (same as name in current implementation).
    public let model: String

    /// Total size of the model in bytes.
    public let size: UInt64

    /// The model's digest/hash.
    public let digest: String

    /// Detailed model information including format, family, and parameters.
    public let details: ModelDetails

    /// When the model will be unloaded from memory if not used.
    public let expiresAt: Date

    /// Amount of VRAM (GPU memory) used by the model in bytes.
    public let sizeVRAM: UInt64

    private enum CodingKeys: String, CodingKey {
        case name, model, size, digest, details
        case expiresAt = "expires_at"
        case sizeVRAM = "size_vram"
    }
}
