import Foundation

/// A tool definition for function calling.
///
/// Defines a function that the model can call during chat completions.
public struct ToolDefinition: Codable, Sendable {
    /// The tool type. Always "function" for function calling.
    public let type: String

    /// The function definition including name, description, and parameters.
    public let function: FunctionDefinition

    public init(type: String = "function", function: FunctionDefinition) {
        self.type = type
        self.function = function
    }
}

/// Definition of a callable function.
///
/// Describes a function that the model can invoke, including its name, purpose, and parameters.
public struct FunctionDefinition: Codable, Sendable {
    /// The function name.
    public let name: String

    /// A description of what the function does.
    public let description: String

    /// The function's parameter schema.
    public let parameters: Parameters

    public init(
        name: String,
        description: String,
        parameters: Parameters
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

public struct Parameters: Codable, Sendable {

    public let type: String

    public let properties: [String: PropertyDefinition]

    public let required: [String]

    public init(
        type: String = "object",
        properties: [String: PropertyDefinition],
        required: [String]
    ) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

public struct PropertyDefinition: Codable, Sendable {

    public let type: String

    public let description: String

    public let enumValues: [String]?

    public init(
        type: String,
        description: String,
        enumValues: [String]? = nil
    ) {
        self.type = type
        self.description = description
        self.enumValues = enumValues
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case description
        case enumValues = "enum"
    }
}
