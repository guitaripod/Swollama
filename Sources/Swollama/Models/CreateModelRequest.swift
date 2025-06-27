import Foundation

/// Parameters for creating a model using the `/api/create` endpoint.
///
/// This request supports three main use cases:
/// 1. Creating a model from another model with customizations
/// 2. Creating a model from a GGUF file
/// 3. Creating a model from Safetensors files
///
/// ## Example Usage
///
/// ### Create from existing model
/// ```swift
/// let request = CreateModelRequest(
///     model: "mario",
///     from: "llama3.2",
///     system: "You are Mario from Super Mario Bros."
/// )
/// ```
///
/// ### Create from GGUF file
/// ```swift
/// let request = CreateModelRequest(
///     model: "my-gguf-model",
///     files: ["test.gguf": "sha256:432f310a77f..."]
/// )
/// ```
///
/// ### Quantize a model
/// ```swift
/// let request = CreateModelRequest(
///     model: "llama3.2:quantized",
///     from: "llama3.2:3b-instruct-fp16",
///     quantize: .q4_K_M
/// )
/// ```
public struct CreateModelRequest: Codable, Sendable {
    /// Name of the model to create
    public let model: String
    /// Name of an existing model to create from (optional)
    public let from: String?
    /// Dictionary of file names to SHA256 digests of blobs to create the model from
    public let files: [String: String]?
    /// Dictionary of file names to SHA256 digests of blobs for LORA adapters
    public let adapters: [String: String]?
    /// The prompt template for the model
    public let template: String?
    /// License(s) for the model
    public let license: StringOrArray?
    /// System prompt for the model
    public let system: String?
    /// Dictionary of parameters for the model
    public let parameters: ModelfileParameters?
    /// List of message objects used to create a conversation
    public let messages: [ModelfileMessage]?
    /// Whether to stream the response
    public let stream: Bool?
    /// Quantization type for non-quantized models
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

/// Quantization types available for model creation
public enum QuantizationType: String, Codable, Sendable {
    case q4_K_M = "q4_K_M"
    case q4_K_S = "q4_K_S"
    case q8_0 = "q8_0"
}

/// Represents either a string or an array of strings
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

/// Parameters that can be set in a Modelfile
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

/// Message object for Modelfile
public struct ModelfileMessage: Codable, Sendable {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}