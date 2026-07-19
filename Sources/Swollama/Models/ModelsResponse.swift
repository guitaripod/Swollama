import Foundation

struct ModelsResponse: Codable {
    let models: [ModelListEntry]
}

/// Information about an available model.
///
/// Represents a model entry from the list models response.
public struct ModelListEntry: Codable, Sendable {
    /// The model's name in full format (e.g., "llama3.2:latest").
    public let name: String

    /// The model identifier (same as name in current implementation).
    public let model: String

    /// When the model was last modified.
    public let modifiedAt: Date

    /// Total size of the model in bytes.
    public let size: UInt64

    /// The model's digest/hash.
    public let digest: String

    /// Detailed model information including format, family, and parameters.
    public let details: ModelDetails

    /// The capabilities the model supports (e.g. `completion`, `tools`, `vision`), when reported.
    public let capabilities: [ModelCapability]?

    /// The upstream cloud model name, for remote/cloud model stubs.
    public let remoteModel: String?

    /// The upstream cloud host, for remote/cloud model stubs.
    public let remoteHost: String?

    private enum CodingKeys: String, CodingKey {
        case name, model, size, digest, details, capabilities
        case modifiedAt = "modified_at"
        case remoteModel = "remote_model"
        case remoteHost = "remote_host"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        model = try container.decode(String.self, forKey: .model)
        size = try container.decode(UInt64.self, forKey: .size)
        digest = try container.decode(String.self, forKey: .digest)
        details = try container.decode(ModelDetails.self, forKey: .details)
        capabilities = try container.decodeIfPresent([ModelCapability].self, forKey: .capabilities)
        remoteModel = try container.decodeIfPresent(String.self, forKey: .remoteModel)
        remoteHost = try container.decodeIfPresent(String.self, forKey: .remoteHost)
        modifiedAt = try OllamaDate.decode(from: container, forKey: .modifiedAt)
    }
}

/// Detailed information about a model.
///
/// Contains technical details about the model's architecture and configuration.
public struct ModelDetails: Codable, Sendable {
    /// The parent model this model is based on.
    public let parentModel: String

    /// The model format (e.g., "gguf").
    public let format: String

    /// The model family (e.g., "llama").
    public let family: String

    /// Additional model families this model belongs to.
    public let families: [String]?

    /// The parameter size (e.g., "3.2B", "7B").
    public let parameterSize: String

    /// The quantization level (e.g., "Q4_K_M", "Q8_0").
    public let quantizationLevel: String

    /// The model's maximum context length, when reported.
    public let contextLength: Int?

    /// The model's embedding dimension, when reported.
    public let embeddingLength: Int?

    private enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format, family, families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
        case contextLength = "context_length"
        case embeddingLength = "embedding_length"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parentModel = try container.decodeIfPresent(String.self, forKey: .parentModel) ?? ""
        format = try container.decodeIfPresent(String.self, forKey: .format) ?? ""
        family = try container.decodeIfPresent(String.self, forKey: .family) ?? ""
        families = try container.decodeIfPresent([String].self, forKey: .families)
        parameterSize = try container.decodeIfPresent(String.self, forKey: .parameterSize) ?? ""
        quantizationLevel =
            try container.decodeIfPresent(String.self, forKey: .quantizationLevel) ?? ""
        contextLength = try container.decodeIfPresent(Int.self, forKey: .contextLength)
        embeddingLength = try container.decodeIfPresent(Int.self, forKey: .embeddingLength)
    }

    public init(
        parentModel: String = "",
        format: String = "",
        family: String = "",
        families: [String]? = nil,
        parameterSize: String = "",
        quantizationLevel: String = "",
        contextLength: Int? = nil,
        embeddingLength: Int? = nil
    ) {
        self.parentModel = parentModel
        self.format = format
        self.family = family
        self.families = families
        self.parameterSize = parameterSize
        self.quantizationLevel = quantizationLevel
        self.contextLength = contextLength
        self.embeddingLength = embeddingLength
    }
}
