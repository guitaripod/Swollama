import Foundation


public struct ToolCall: Codable, Sendable {

    public let function: FunctionCall

    public init(function: FunctionCall) {
        self.function = function
    }
}


public struct FunctionCall: Codable, Sendable {

    public let name: String

    public let arguments: String

    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }
}
