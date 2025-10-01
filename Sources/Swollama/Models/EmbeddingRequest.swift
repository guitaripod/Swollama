import Foundation


public struct EmbeddingRequest: Codable, Sendable {
    public init(model: String, input: EmbeddingInput, truncate: Bool? = nil, options: ModelOptions? = nil, keepAlive: TimeInterval? = nil) {
        self.model = model
        self.input = input
        self.truncate = truncate
        self.options = options
        self.keepAlive = keepAlive
    }


    public let model: String

    public let input: EmbeddingInput

    public let truncate: Bool?

    public let options: ModelOptions?

    public let keepAlive: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case model, input, truncate, options
        case keepAlive = "keep_alive"
    }
}


public enum EmbeddingInput: Codable, Sendable {
    case single(String)
    case multiple([String])

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let string):
            try container.encode(string)
        case .multiple(let array):
            try container.encode(array)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .single(string)
        } else if let array = try? container.decode([String].self) {
            self = .multiple(array)
        } else {
            throw DecodingError.typeMismatch(
                EmbeddingInput.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or [String]"
                )
            )
        }
    }
}
