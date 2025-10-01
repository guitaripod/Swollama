import Foundation



































public struct CreateModelRequest: Codable, Sendable {

    public let model: String

    public let from: String?

    public let files: [String: String]?

    public let adapters: [String: String]?

    public let template: String?

    public let license: StringOrArray?

    public let system: String?

    public let parameters: ModelfileParameters?

    public let messages: [ModelfileMessage]?

    public let stream: Bool?

    public let quantize: QuantizationType?

    public init(
        model: String,
        from: String? = nil,
        files: [String: String]? = nil,
        adapters: [String: String]? = nil,
        template: String? = nil,
        license: StringOrArray? = nil,
        system: String? = nil,
        parameters: ModelfileParameters? = nil,
        messages: [ModelfileMessage]? = nil,
        stream: Bool? = nil,
        quantize: QuantizationType? = nil
    ) {
        self.model = model
        self.from = from
        self.files = files
        self.adapters = adapters
        self.template = template
        self.license = license
        self.system = system
        self.parameters = parameters
        self.messages = messages
        self.stream = stream
        self.quantize = quantize
    }
}


public enum QuantizationType: String, Codable, Sendable {
    case q4_K_M = "q4_K_M"
    case q4_K_S = "q4_K_S"
    case q8_0 = "q8_0"
}


public enum StringOrArray: Codable, Sendable {
    case string(String)
    case array([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected either a string or an array of strings")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .array(let arr):
            try container.encode(arr)
        }
    }
}


public struct ModelfileParameters: Codable, Sendable {
    public let mirostat: Int?
    public let mirostatEta: Double?
    public let mirostatTau: Double?
    public let numCtx: Int?
    public let repeatLastN: Int?
    public let repeatPenalty: Double?
    public let temperature: Double?
    public let seed: UInt32?
    public let stop: [String]?
    public let tfsZ: Double?
    public let numPredict: Int?
    public let topK: Int?
    public let topP: Double?
    public let minP: Double?

    private enum CodingKeys: String, CodingKey {
        case mirostat
        case mirostatEta = "mirostat_eta"
        case mirostatTau = "mirostat_tau"
        case numCtx = "num_ctx"
        case repeatLastN = "repeat_last_n"
        case repeatPenalty = "repeat_penalty"
        case temperature
        case seed
        case stop
        case tfsZ = "tfs_z"
        case numPredict = "num_predict"
        case topK = "top_k"
        case topP = "top_p"
        case minP = "min_p"
    }

    public init(
        mirostat: Int? = nil,
        mirostatEta: Double? = nil,
        mirostatTau: Double? = nil,
        numCtx: Int? = nil,
        repeatLastN: Int? = nil,
        repeatPenalty: Double? = nil,
        temperature: Double? = nil,
        seed: UInt32? = nil,
        stop: [String]? = nil,
        tfsZ: Double? = nil,
        numPredict: Int? = nil,
        topK: Int? = nil,
        topP: Double? = nil,
        minP: Double? = nil
    ) {
        self.mirostat = mirostat
        self.mirostatEta = mirostatEta
        self.mirostatTau = mirostatTau
        self.numCtx = numCtx
        self.repeatLastN = repeatLastN
        self.repeatPenalty = repeatPenalty
        self.temperature = temperature
        self.seed = seed
        self.stop = stop
        self.tfsZ = tfsZ
        self.numPredict = numPredict
        self.topK = topK
        self.topP = topP
        self.minP = minP
    }
}


public struct ModelfileMessage: Codable, Sendable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}