import Foundation

/// Options for chat completion
public struct ChatOptions {
    public let tools: [ToolDefinition]?
    public let format: ResponseFormat?
    public let modelOptions: ModelOptions?
    public let keepAlive: TimeInterval?

    public init(
        tools: [ToolDefinition]? = nil,
        format: ResponseFormat? = nil,
        modelOptions: ModelOptions? = nil,
        keepAlive: TimeInterval? = nil
    ) {
        self.tools = tools
        self.format = format
        self.modelOptions = modelOptions
        self.keepAlive = keepAlive
    }

    public static let `default` = ChatOptions()
}
