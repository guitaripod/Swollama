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

/// A message in a chat conversation.
///
/// Represents a single message with a role (system, user, assistant, or tool), text content,
/// and optional attachments like images or tool call information.
public struct ChatMessage: Codable, Sendable {
    /// The role of the message sender.
    public let role: MessageRole

    /// The text content of the message.
    public let content: String

    /// Optional base64-encoded images attached to the message (for multimodal models).
    public let images: [String]?

    /// Tool calls made by the assistant (for function calling).
    public let toolCalls: [ToolCall]?

    /// Extended thinking/reasoning content (for reasoning models with `think` enabled).
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

/// The role of a message sender in a chat conversation.
public enum MessageRole: String, Codable, Sendable {
    /// System message defining assistant behavior and context.
    case system
    /// User message containing prompts or questions.
    case user
    /// Assistant message containing model responses.
    case assistant
    /// Tool message containing function call results.
    case tool
}
