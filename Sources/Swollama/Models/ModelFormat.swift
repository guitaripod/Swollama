import Foundation


public enum ModelFormat: String, Codable {

    case gguf


    case safetensors


    case pytorch


    case unknown




    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = ModelFormat(rawValue: value.lowercased()) ?? .unknown
    }
}
