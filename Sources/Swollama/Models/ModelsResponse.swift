import Foundation


struct ModelsResponse: Codable {
    let models: [ModelListEntry]
}


public struct ModelListEntry: Codable, Sendable {

    public let name: String

    public let model: String

    public let modifiedAt: Date

    public let size: UInt64

    public let digest: String

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


public struct ModelDetails: Codable, Sendable {

    public let parentModel: String

    public let format: String

    public let family: String

    public let families: [String]?

    public let parameterSize: String

    public let quantizationLevel: String

    private enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format, family, families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
}
