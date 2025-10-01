import Foundation

/// A tool call made by the model.
///
/// Represents a function call that the model wants to invoke.
public struct ToolCall: Codable, Sendable {
    /// The function call details.
    public let function: FunctionCall

    public init(function: FunctionCall) {
        self.function = function
    }
}


/// Details of a function call.
///
/// Contains the function name and arguments as a JSON string.
public struct FunctionCall: Codable, Sendable {
    /// The name of the function to call.
    public let name: String

    /// The function arguments as a JSON string.
    public let arguments: String

    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }
}
