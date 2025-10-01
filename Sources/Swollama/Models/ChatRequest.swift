import Foundation


public struct ChatRequest: Codable, Sendable {

    public let model: String

    public let messages: [ChatMessage]

    public let tools: [ToolDefinition]?

    public let format: ResponseFormat?

    public let options: ModelOptions?

    public let stream: Bool?

    public let keepAlive: TimeInterval?

    public let think: Bool?

    private enum CodingKeys: String, CodingKey {
        case model, messages, tools, format, options, stream, think
        case keepAlive = "keep_alive"
    }

    public init(
        model: String,
        messages: [ChatMessage],
        tools: [ToolDefinition]? = nil,
        format: ResponseFormat? = nil,
        options: ModelOptions? = nil,
        stream: Bool? = nil,
        keepAlive: TimeInterval? = nil,
        think: Bool? = nil
    ) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.format = format
        self.options = options
        self.stream = stream
        self.keepAlive = keepAlive
        self.think = think
    }
}


public struct ChatMessage: Codable, Sendable {

    public let role: MessageRole

    public let content: String


    public let images: [String]?

    public let toolCalls: [ToolCall]?

    public let thinking: String?

    private enum CodingKeys: String, CodingKey {
        case role, content, images, thinking
        case toolCalls = "tool_calls"
    }

    public init(
        role: MessageRole,
        content: String,
        images: [String]? = nil,
        toolCalls: [ToolCall]? = nil,
        thinking: String? = nil
    ) {
        self.role = role
        self.content = content
        self.images = images
        self.toolCalls = toolCalls
        self.thinking = thinking
    }
}


public enum MessageRole: String, Codable, Sendable {
    case system
    case user
    case assistant
    case tool
}
