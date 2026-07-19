import Foundation

/// Detailed information about a specific model, as returned by `POST /api/show`.
///
/// Contains the model's configuration including its modelfile, parameters, prompt template,
/// architecture metadata, tensor layout, and declared capabilities.
public struct ModelInformation: Codable, Sendable {
    /// The modelfile content that defines the model.
    public let modelfile: String?

    /// Model parameters as a newline-delimited string, if the model defines any.
    public let parameters: String?

    /// The prompt template used by the model.
    public let template: String?

    /// The model's license text, if present.
    public let license: String?

    /// The model's default system prompt, if it defines one.
    public let system: String?

    /// The named renderer used to format prompts for the model (e.g. a harmony pipeline), if any.
    public let renderer: String?

    /// The named output parser used to interpret the model's output (e.g. `"harmony"`), if any.
    public let parser: String?

    /// Baked default conversation messages stored with the model, if any.
    public let messages: [ChatMessage]?

    /// Technical details about the model's architecture (format, family, sizes).
    public let details: ModelDetails

    /// Architecture and tokenizer metadata (e.g. `llama.context_length`, `general.parameter_count`).
    ///
    /// Keys and value types vary by architecture; values are exposed as ``JSONValue``.
    public let modelInfo: [String: JSONValue]?

    /// The model's tensor layout. Only populated when the model is shown with `verbose: true`.
    public let tensors: [ModelTensor]?

    /// The capabilities the model supports (e.g. `completion`, `tools`, `vision`, `thinking`).
    public let capabilities: [ModelCapability]?

    /// When the model was last modified, if reported.
    public let modifiedAt: Date?

    /// The minimum Ollama server version required to run the model, if reported.
    public let requires: String?

    /// Multimodal projector (mmproj) metadata for vision/audio models, if present.
    public let projectorInfo: [String: JSONValue]?

    /// The upstream cloud model name, when this is a remote/cloud model stub.
    public let remoteModel: String?

    /// The upstream cloud host, when this is a remote/cloud model stub.
    public let remoteHost: String?

    private enum CodingKeys: String, CodingKey {
        case modelfile, parameters, template, license, system, renderer, parser, messages, details
        case modelInfo = "model_info"
        case tensors, capabilities, requires
        case modifiedAt = "modified_at"
        case projectorInfo = "projector_info"
        case remoteModel = "remote_model"
        case remoteHost = "remote_host"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modelfile = try container.decodeIfPresent(String.self, forKey: .modelfile)
        parameters = try container.decodeIfPresent(String.self, forKey: .parameters)
        template = try container.decodeIfPresent(String.self, forKey: .template)
        license = try container.decodeIfPresent(String.self, forKey: .license)
        system = try container.decodeIfPresent(String.self, forKey: .system)
        renderer = try container.decodeIfPresent(String.self, forKey: .renderer)
        parser = try container.decodeIfPresent(String.self, forKey: .parser)
        messages = try container.decodeIfPresent([ChatMessage].self, forKey: .messages)
        details = try container.decode(ModelDetails.self, forKey: .details)
        modelInfo = try container.decodeIfPresent([String: JSONValue].self, forKey: .modelInfo)
        tensors = try container.decodeIfPresent([ModelTensor].self, forKey: .tensors)
        capabilities = try container.decodeIfPresent([ModelCapability].self, forKey: .capabilities)
        requires = try container.decodeIfPresent(String.self, forKey: .requires)
        projectorInfo = try container.decodeIfPresent(
            [String: JSONValue].self,
            forKey: .projectorInfo
        )
        remoteModel = try container.decodeIfPresent(String.self, forKey: .remoteModel)
        remoteHost = try container.decodeIfPresent(String.self, forKey: .remoteHost)

        if let modifiedString = try container.decodeIfPresent(String.self, forKey: .modifiedAt) {
            modifiedAt = OllamaDate.parse(modifiedString)
        } else {
            modifiedAt = nil
        }
    }

    public init(
        modelfile: String? = nil,
        parameters: String? = nil,
        template: String? = nil,
        license: String? = nil,
        system: String? = nil,
        renderer: String? = nil,
        parser: String? = nil,
        messages: [ChatMessage]? = nil,
        details: ModelDetails,
        modelInfo: [String: JSONValue]? = nil,
        tensors: [ModelTensor]? = nil,
        capabilities: [ModelCapability]? = nil,
        modifiedAt: Date? = nil,
        requires: String? = nil,
        projectorInfo: [String: JSONValue]? = nil,
        remoteModel: String? = nil,
        remoteHost: String? = nil
    ) {
        self.modelfile = modelfile
        self.parameters = parameters
        self.template = template
        self.license = license
        self.system = system
        self.renderer = renderer
        self.parser = parser
        self.messages = messages
        self.details = details
        self.modelInfo = modelInfo
        self.tensors = tensors
        self.capabilities = capabilities
        self.modifiedAt = modifiedAt
        self.requires = requires
        self.projectorInfo = projectorInfo
        self.remoteModel = remoteModel
        self.remoteHost = remoteHost
    }
}

/// A single tensor in a model's weight layout.
public struct ModelTensor: Codable, Sendable {
    /// The tensor's name (e.g. `blk.0.attn_q.weight`).
    public let name: String

    /// The tensor's data type (e.g. `Q4_K`, `F32`).
    public let type: String

    /// The tensor's dimensions.
    public let shape: [Int]

    public init(name: String, type: String, shape: [Int]) {
        self.name = name
        self.type = type
        self.shape = shape
    }
}

/// A capability a model supports, as reported by `/api/show` and `/api/tags`.
///
/// Modeled as an extensible value type so capabilities added by future Ollama releases decode
/// without loss instead of failing.
public struct ModelCapability: RawRepresentable, Codable, Sendable, Hashable,
    ExpressibleByStringLiteral
{
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// The model can generate text completions.
    public static let completion = ModelCapability(rawValue: "completion")
    /// The model supports tool / function calling.
    public static let tools = ModelCapability(rawValue: "tools")
    /// The model accepts image inputs.
    public static let vision = ModelCapability(rawValue: "vision")
    /// The model accepts audio inputs.
    public static let audio = ModelCapability(rawValue: "audio")
    /// The model supports thinking / reasoning output.
    public static let thinking = ModelCapability(rawValue: "thinking")
    /// The model produces embeddings.
    public static let embedding = ModelCapability(rawValue: "embedding")
    /// The model supports fill-in-the-middle insertion (suffix).
    public static let insert = ModelCapability(rawValue: "insert")
}
