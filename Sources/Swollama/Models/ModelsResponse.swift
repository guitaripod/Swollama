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

    private enum CodingKeys: String, CodingKey {
        case name, model, size, digest, details
        case modifiedAt = "modified_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        model = try container.decode(String.self, forKey: .model)
        size = try container.decode(UInt64.self, forKey: .size)
        digest = try container.decode(String.self, forKey: .digest)
        details = try container.decode(ModelDetails.self, forKey: .details)


        let dateString = try container.decode(String.self, forKey: .modifiedAt)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = formatter.date(from: dateString) {
            modifiedAt = date
        } else {

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = formatter.date(from: dateString) {
                modifiedAt = date
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath + [CodingKeys.modifiedAt],
                        debugDescription: "Date string '\(dateString)' does not match expected format",
                        underlyingError: nil
                    )
                )
            }
        }
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

    private enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format, family, families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
}
