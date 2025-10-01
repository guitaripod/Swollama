import Foundation

/// Events emitted during agent execution.
///
/// `AgentEvent` represents observable stages in an agent's workflow, allowing you to monitor
/// the agent's reasoning, tool usage, and responses in real-time.
///
/// ## Overview
///
/// The agent emits events in this typical sequence:
/// 1. ``thinking(_:)`` - The model's reasoning process (if enabled)
/// 2. ``toolCall(name:arguments:)`` - A tool being invoked
/// 3. ``toolResult(name:content:)`` - The result from the tool
/// 4. Steps 1-3 repeat as needed
/// 5. ``message(_:)`` - The final answer
/// 6. ``done`` - Workflow complete
///
/// ## Example
///
/// ```swift
/// for try await event in agent.run(prompt: "What is Swift?", model: model) {
///     switch event {
///     case .thinking(let text):
///         print("💭 \(text)")
///     case .toolCall(let name, _):
///         print("🔧 Calling \(name)")
///     case .toolResult(let name, let content):
///         print("📊 Result from \(name)")
///     case .message(let text):
///         print("💬 \(text)")
///     case .done:
///         print("✅ Complete")
///     }
/// }
/// ```
public enum AgentEvent: Sendable {
    /// The model's reasoning process before taking action.
    ///
    /// Contains the extended thinking content from reasoning models when ``AgentConfiguration/enableThinking`` is true.
    case thinking(String)

    /// A tool is being invoked by the model.
    ///
    /// - Parameters:
    ///   - name: The name of the tool being called (e.g., "web_search").
    ///   - arguments: JSON string containing the tool's parameters.
    case toolCall(name: String, arguments: String)

    /// The result returned from a tool execution.
    ///
    /// - Parameters:
    ///   - name: The name of the tool that was executed.
    ///   - content: The result content from the tool (possibly truncated).
    case toolResult(name: String, content: String)

    /// The final response message from the model.
    ///
    /// Contains the model's answer after completing all necessary tool calls.
    case message(String)

    /// The agent workflow has completed successfully.
    case done
}

extension AgentEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .thinking(let text):
            return "Thinking: \(text)"
        case .toolCall(let name, let args):
            return "Tool Call: \(name) with arguments: \(args)"
        case .toolResult(let name, let content):
            let preview = String(content.prefix(100))
            return "Tool Result (\(name)): \(preview)..."
        case .message(let text):
            return "Message: \(text)"
        case .done:
            return "Done"
        }
    }
}
