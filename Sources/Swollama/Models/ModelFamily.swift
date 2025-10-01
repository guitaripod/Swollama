import Foundation


public enum ModelFamily: String, Codable {
    case llama
    case mistral
    case vicuna
    case codellama
    case other

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = ModelFamily(rawValue: value.lowercased()) ?? .other
    }
}
