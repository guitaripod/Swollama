import Foundation


public struct GenerateRequest: Codable, Sendable {

    public let model: String

    public let prompt: String

    public let suffix: String?

    public let images: [String]?

    public let format: ResponseFormat?

    public let options: ModelOptions?

    public let system: String?

    public let template: String?

    public let context: [Int]?

    public let stream: Bool?

    public let raw: Bool?

    public let keepAlive: TimeInterval?

    public let think: Bool?

    private enum CodingKeys: String, CodingKey {
        case model, prompt, suffix, images, format, options, system
        case template, context, stream, raw, think
        case keepAlive = "keep_alive"
    }

    public init(
        model: String,
        prompt: String,
        suffix: String? = nil,
        images: [String]? = nil,
        format: ResponseFormat? = nil,
        options: ModelOptions? = nil,
        system: String? = nil,
        template: String? = nil,
        context: [Int]? = nil,
        stream: Bool? = nil,
        raw: Bool? = nil,
        keepAlive: TimeInterval? = nil,
        think: Bool? = nil
    ) {
        self.model = model
        self.prompt = prompt
        self.suffix = suffix
        self.images = images
        self.format = format
        self.options = options
        self.system = system
        self.template = template
        self.context = context
        self.stream = stream
        self.raw = raw
        self.keepAlive = keepAlive
        self.think = think
    }
}


/// Response format constraint for model outputs.
///
/// Constrains the model to generate responses in a specific format.
public enum ResponseFormat: Codable, Sendable {
    /// Generate unstructured JSON output.
    case json

    /// Generate structured output conforming to a JSON schema.
    case jsonSchema(JSONSchema)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()


        if let stringValue = try? container.decode(String.self), stringValue == "json" {
            self = .json
            return
        }


        if let schema = try? container.decode(JSONSchema.self) {
            self = .jsonSchema(schema)
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "ResponseFormat must be either 'json' or a JSON Schema object")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .json:
            try container.encode("json")
        case .jsonSchema(let schema):
            try container.encode(schema)
        }
    }
}





















/// A JSON Schema definition for structured output.
///
/// Defines the structure of JSON output that the model should generate, including
/// type information, properties, and constraints.
public struct JSONSchema: Codable, Sendable {
    /// The JSON type (e.g., "object", "array").
    public let type: String

    /// Property definitions for object types.
    public let properties: [String: JSONSchemaProperty]?

    /// Required property names for object types.
    public let required: [String]?

    /// Item definition for array types.
    public let items: JSONSchemaProperty?

    /// Whether additional properties are allowed for object types.
    public let additionalProperties: JSONSchemaPropertyOrBool?

    public init(
        type: String,
        properties: [String: JSONSchemaProperty]? = nil,
        required: [String]? = nil,
        items: JSONSchemaProperty? = nil,
        additionalProperties: JSONSchemaPropertyOrBool? = nil
    ) {
        self.type = type
        self.properties = properties
        self.required = required
        self.items = items
        self.additionalProperties = additionalProperties
    }
}


public indirect enum JSONSchemaProperty: Codable, Sendable {
    case simple(type: String, description: String?, enum: [String]?)
    case array(type: String, items: JSONSchemaProperty, description: String?)
    case object(type: String, properties: [String: JSONSchemaProperty], required: [String]?, description: String?)

    public init(
        type: String,
        description: String? = nil,
        enum: [String]? = nil,
        items: JSONSchemaProperty? = nil,
        properties: [String: JSONSchemaProperty]? = nil,
        required: [String]? = nil
    ) {
        if let items = items {
            self = .array(type: type, items: items, description: description)
        } else if let properties = properties {
            self = .object(type: type, properties: properties, required: required, description: description)
        } else {
            self = .simple(type: type, description: description, enum: `enum`)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, description, `enum`, items, properties, required
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let description = try container.decodeIfPresent(String.self, forKey: .description)

        if let items = try container.decodeIfPresent(JSONSchemaProperty.self, forKey: .items) {
            self = .array(type: type, items: items, description: description)
        } else if let properties = try container.decodeIfPresent([String: JSONSchemaProperty].self, forKey: .properties) {
            let required = try container.decodeIfPresent([String].self, forKey: .required)
            self = .object(type: type, properties: properties, required: required, description: description)
        } else {
            let enumValues = try container.decodeIfPresent([String].self, forKey: .enum)
            self = .simple(type: type, description: description, enum: enumValues)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .simple(let type, let description, let enumValues):
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(enumValues, forKey: .enum)

        case .array(let type, let items, let description):
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encode(items, forKey: .items)

        case .object(let type, let properties, let required, let description):
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encode(properties, forKey: .properties)
            try container.encodeIfPresent(required, forKey: .required)
        }
    }
}



public enum JSONSchemaPropertyOrBool: Codable, Sendable {
    case property(JSONSchemaProperty)
    case bool(Bool)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let property = try? container.decode(JSONSchemaProperty.self) {
            self = .property(property)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected either a boolean or a JSON Schema property")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .property(let prop):
            try container.encode(prop)
        case .bool(let bool):
            try container.encode(bool)
        }
    }
}


public struct ModelOptions: Codable, Sendable {
    public let numKeep: Int?
    public let seed: UInt32?
    public let numPredict: Int?
    public let topK: Int?
    public let topP: Double?
    public let minP: Double?
    public let tfsZ: Double?
    public let typicalP: Double?
    public let repeatLastN: Int?
    public let temperature: Double?
    public let repeatPenalty: Double?
    public let presencePenalty: Double?
    public let frequencyPenalty: Double?
    public let mirostat: Int?
    public let mirostatTau: Double?
    public let mirostatEta: Double?
    public let penalizeNewline: Bool?
    public let stop: [String]?
    public let numa: Bool?
    public let numCtx: Int?
    public let numBatch: Int?
    public let numGPU: Int?
    public let mainGPU: Int?
    public let lowVRAM: Bool?
    public let f16KV: Bool?
    public let vocabOnly: Bool?
    public let useMMap: Bool?
    public let useMLock: Bool?
    public let numThread: Int?

    private enum CodingKeys: String, CodingKey {
        case numKeep = "num_keep"
        case seed
        case numPredict = "num_predict"
        case topK = "top_k"
        case topP = "top_p"
        case minP = "min_p"
        case tfsZ = "tfs_z"
        case typicalP = "typical_p"
        case repeatLastN = "repeat_last_n"
        case temperature
        case repeatPenalty = "repeat_penalty"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case mirostat
        case mirostatTau = "mirostat_tau"
        case mirostatEta = "mirostat_eta"
        case penalizeNewline = "penalize_newline"
        case stop
        case numa
        case numCtx = "num_ctx"
        case numBatch = "num_batch"
        case numGPU = "num_gpu"
        case mainGPU = "main_gpu"
        case lowVRAM = "low_vram"
        case f16KV = "f16_kv"
        case vocabOnly = "vocab_only"
        case useMMap = "use_mmap"
        case useMLock = "use_mlock"
        case numThread = "num_thread"
    }

    public init(
        numKeep: Int? = nil,
        seed: UInt32? = nil,
        numPredict: Int? = nil,
        topK: Int? = nil,
        topP: Double? = nil,
        minP: Double? = nil,
        tfsZ: Double? = nil,
        typicalP: Double? = nil,
        repeatLastN: Int? = nil,
        temperature: Double? = nil,
        repeatPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        mirostat: Int? = nil,
        mirostatTau: Double? = nil,
        mirostatEta: Double? = nil,
        penalizeNewline: Bool? = nil,
        stop: [String]? = nil,
        numa: Bool? = nil,
        numCtx: Int? = nil,
        numBatch: Int? = nil,
        numGPU: Int? = nil,
        mainGPU: Int? = nil,
        lowVRAM: Bool? = nil,
        f16KV: Bool? = nil,
        vocabOnly: Bool? = nil,
        useMMap: Bool? = nil,
        useMLock: Bool? = nil,
        numThread: Int? = nil
    ) {
        self.numKeep = numKeep
        self.seed = seed
        self.numPredict = numPredict
        self.topK = topK
        self.topP = topP
        self.minP = minP
        self.tfsZ = tfsZ
        self.typicalP = typicalP
        self.repeatLastN = repeatLastN
        self.temperature = temperature
        self.repeatPenalty = repeatPenalty
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.mirostat = mirostat
        self.mirostatTau = mirostatTau
        self.mirostatEta = mirostatEta
        self.penalizeNewline = penalizeNewline
        self.stop = stop
        self.numa = numa
        self.numCtx = numCtx
        self.numBatch = numBatch
        self.numGPU = numGPU
        self.mainGPU = mainGPU
        self.lowVRAM = lowVRAM
        self.f16KV = f16KV
        self.vocabOnly = vocabOnly
        self.useMMap = useMMap
        self.useMLock = useMLock
        self.numThread = numThread
    }
}
