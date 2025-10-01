import Foundation

/// Structured representation of an Ollama model name.
///
/// Model names in Ollama follow the format `[namespace/]name[:tag]`, where:
/// - `namespace` is optional and used for registry-hosted models (e.g., "library", "username")
/// - `name` is the model identifier (e.g., "llama3.2", "mistral")
/// - `tag` specifies the version or variant, defaulting to "latest"
///
/// ## Example
///
/// ```swift
/// let model1 = OllamaModelName(name: "llama3.2")
/// print(model1.fullName)
///
/// let model2 = OllamaModelName(name: "mistral", tag: "7b-instruct")
/// print(model2.fullName)
///
/// guard let model3 = OllamaModelName.parse("username/custom-model:v1") else {
///     throw OllamaError.invalidParameters("Invalid model name")
/// }
/// print(model3.namespace)
/// ```
public struct OllamaModelName {
    /// The model's namespace (e.g., "library", "username"). Optional for local-only models.
    public let namespace: String?

    /// The model's name (e.g., "llama3.2", "mistral").
    public let name: String

    /// The model's tag/version (e.g., "latest", "7b-instruct"). Defaults to "latest".
    public let tag: String






    /// Creates a model name with the specified components.
    ///
    /// - Parameters:
    ///   - namespace: Optional namespace for registry-hosted models.
    ///   - name: The model name.
    ///   - tag: The model tag/version. Defaults to "latest".
    public init(namespace: String? = nil, name: String, tag: String = "latest") {
        self.namespace = namespace
        self.name = name
        self.tag = tag
    }

    /// Parses a model name string into structured components.
    ///
    /// Accepts formats like "llama3.2", "mistral:7b-instruct", or "username/model:tag".
    ///
    /// - Parameter string: The model name string to parse.
    /// - Returns: A parsed ``OllamaModelName`` or `nil` if the format is invalid.
    public static func parse(_ string: String) -> OllamaModelName? {
        let components = string.split(separator: "/")
        switch components.count {
        case 1:
            let nameComponents = components[0].split(separator: ":")
            guard let name = nameComponents.first else { return nil }
            let tag = nameComponents.count > 1 ? String(nameComponents[1]) : "latest"
            return OllamaModelName(name: String(name), tag: tag)
        case 2:
            let nameComponents = components[1].split(separator: ":")
            guard let name = nameComponents.first else { return nil }
            let tag = nameComponents.count > 1 ? String(nameComponents[1]) : "latest"
            return OllamaModelName(namespace: String(components[0]), name: String(name), tag: tag)
        default:
            return nil
        }
    }


    /// The complete model name string in Ollama format.
    ///
    /// Returns the fully-qualified model name including namespace (if present), name, and tag.
    /// Examples: "llama3.2:latest", "username/model:v1".
    public var fullName: String {
        if let namespace = namespace {
            return "\(namespace)/\(name):\(tag)"
        }
        return "\(name):\(tag)"
    }
}
