import Foundation

public struct ChatRequest: Codable, Sendable {

    public let model: String

    public let messages: [ChatMessage]

    public let tools: [ToolDefinition]?

    public let format: ResponseFormat?

    public let options: ModelOptions?

    public let stream: Bool?

    public let keepAlive: TimeInterval?

    public let think: ThinkingMode?

    /// Return per-token log-probabilities.
    public let logprobs: Bool?

    /// Number of top alternative tokens to return per position (0–20). Requires `logprobs`.
    public let topLogprobs: Int?

    /// Whether to trim the oldest history when the prompt exceeds the context window. Defaults to `true`.
    public let truncate: Bool?

    /// Whether to slide the context window when the prompt overflows, instead of erroring. Defaults to `true`.
    public let shift: Bool?

    private enum CodingKeys: String, CodingKey {
        case model, messages, tools, format, options, stream, think
        case logprobs, truncate, shift
        case topLogprobs = "top_logprobs"
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
        think: ThinkingMode? = nil,
        logprobs: Bool? = nil,
        topLogprobs: Int? = nil,
        truncate: Bool? = nil,
        shift: Bool? = nil
    ) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.format = format
        self.options = options
        self.stream = stream
        self.keepAlive = keepAlive
        self.think = think
        self.logprobs = logprobs
        self.topLogprobs = topLogprobs
        self.truncate = truncate
        self.shift = shift
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

    /// The name of the tool that produced this message. Set on messages with the ``MessageRole/tool`` role
    /// so the model can associate a tool result with the tool call that requested it.
    public let toolName: String?

    /// The identifier of the tool call this message answers, correlating a ``MessageRole/tool`` result
    /// with the ``ToolCall/id`` that requested it.
    public let toolCallId: String?

    /// Extended thinking/reasoning content (for reasoning models with `think` enabled).
    public let thinking: String?

    private enum CodingKeys: String, CodingKey {
        case role, content, images, thinking
        case toolCalls = "tool_calls"
        case toolName = "tool_name"
        case toolCallId = "tool_call_id"
    }

    public init(
        role: MessageRole,
        content: String,
        images: [String]? = nil,
        toolCalls: [ToolCall]? = nil,
        toolName: String? = nil,
        toolCallId: String? = nil,
        thinking: String? = nil
    ) {
        self.role = role
        self.content = content
        self.images = images
        self.toolCalls = toolCalls
        self.toolName = toolName
        self.toolCallId = toolCallId
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
