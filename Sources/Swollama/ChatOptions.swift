import Foundation


public struct ChatOptions {
    public let tools: [ToolDefinition]?
    public let format: ResponseFormat?
    public let modelOptions: ModelOptions?
    public let keepAlive: TimeInterval?
    public let think: Bool?

    public init(
        tools: [ToolDefinition]? = nil,
        format: ResponseFormat? = nil,
        modelOptions: ModelOptions? = nil,
        keepAlive: TimeInterval? = nil,
        think: Bool? = nil
    ) {
        self.tools = tools
        self.format = format
        self.modelOptions = modelOptions
        self.keepAlive = keepAlive
        self.think = think
    }

    public static let `default` = ChatOptions()
}
