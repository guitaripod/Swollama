import Foundation


public enum AgentEvent: Sendable {
    case thinking(String)

    case toolCall(name: String, arguments: String)

    case toolResult(name: String, content: String)

    case message(String)

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
