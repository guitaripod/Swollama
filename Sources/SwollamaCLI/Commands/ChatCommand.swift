import Foundation
import Swollama


enum TerminalStyle {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"


    static let neonPink = "\u{001B}[38;2;255;20;147m"
    static let neonBlue = "\u{001B}[38;2;0;255;255m"
    static let neonGreen = "\u{001B}[38;2;0;255;127m"
    static let neonYellow = "\u{001B}[38;2;255;215;0m"
    static let mutedPurple = "\u{001B}[38;2;147;112;219m"


    static let bgDark = "\u{001B}[48;2;25;25;35m"
}

struct ChatCommand: CommandProtocol {
    private let client: OllamaProtocol
    private let dateFormatter: DateFormatter

    init(client: OllamaProtocol) {
        self.client = client

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm:ss"
    }

    private func printHeader(model: OllamaModelName) {
        print("\n\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)╔════════════════════════════════════════╗\(TerminalStyle.reset)")
        print("\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)║\(TerminalStyle.neonPink) ChatBot Interface: \(TerminalStyle.neonGreen)\(model.fullName)\(TerminalStyle.neonBlue) ║\(TerminalStyle.reset)")
        print("\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)╚════════════════════════════════════════╝\(TerminalStyle.reset)\n")

        print("\(TerminalStyle.mutedPurple)Available Commands:")
        print("• Type '\(TerminalStyle.neonYellow)exit\(TerminalStyle.mutedPurple)' or '\(TerminalStyle.neonYellow)quit\(TerminalStyle.mutedPurple)' to end the conversation")
        print("• Type '\(TerminalStyle.neonYellow)clear\(TerminalStyle.mutedPurple)' to start a new conversation")
        print("• Type '\(TerminalStyle.neonYellow)/system <message>\(TerminalStyle.mutedPurple)' to set a system message\(TerminalStyle.reset)")
        print("\(TerminalStyle.neonBlue)═══════════════════════════════════════════════\(TerminalStyle.reset)\n")
    }

    private func printTimestamp() {
        let timestamp = dateFormatter.string(from: Date())
        print("\(TerminalStyle.dim)[\(timestamp)]\(TerminalStyle.reset) ", terminator: "")
    }

    private func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }

    func execute(with arguments: [String]) async throws {
        guard !arguments.isEmpty else {
            throw CLIError.missingArgument("Model name required")
        }

        guard let model = OllamaModelName.parse(arguments[0]) else {
            throw CLIError.invalidArgument("Invalid model name format")
        }

        clearScreen()
        printHeader(model: model)

        var messages: [ChatMessage] = []

        while true {
            printTimestamp()
            print("\(TerminalStyle.neonGreen)You:\(TerminalStyle.reset) ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                break
            }

            switch input.lowercased() {
            case "exit", "quit":
                print("\n\(TerminalStyle.neonPink)Goodbye! Chat session ended.\(TerminalStyle.reset)")
                return
            case "clear":
                clearScreen()
                printHeader(model: model)
                messages.removeAll()
                continue
            case "":
                continue
            default:
                if input.starts(with: "/system ") {
                    let systemMessage = String(input.dropFirst(8))
                    messages = messages.filter { $0.role != .system }
                    messages.insert(ChatMessage(role: .system, content: systemMessage), at: 0)
                    print("\n\(TerminalStyle.neonYellow)System message updated.\(TerminalStyle.reset)")
                    continue
                }

                messages.append(ChatMessage(role: .user, content: input))
            }

            printTimestamp()
            print("\(TerminalStyle.neonBlue)Assistant:\(TerminalStyle.reset) ", terminator: "")
            fflush(stdout)

            guard let client = client as? OllamaClient else {
                print("\(TerminalStyle.neonPink)Error: Chat functionality requires OllamaClient\(TerminalStyle.reset)")
                return
            }

            do {
                let stream = try await client.chat(
                    messages: messages,
                    model: model,
                    options: .default
                )

                var fullResponse = ""

                for try await response in stream {
                    if !response.message.content.isEmpty {
                        let content = response.message.content
                        print(content, terminator: "")
                        fflush(stdout)
                        fullResponse += content
                    }

                    if response.done {
                        messages.append(ChatMessage(role: .assistant, content: fullResponse))
                    }
                }

                print("\n\(TerminalStyle.neonBlue)────────────────────────────────────────────\(TerminalStyle.reset)")

            } catch {
                print("\n\(TerminalStyle.neonPink)Error during chat: \(error)\(TerminalStyle.reset)")
                if let ollamaError = error as? OllamaError {
                    let errorMessage = switch ollamaError {
                    case .modelNotFound:
                        "Model '\(model.fullName)' not found. Please check the model name and try again."
                    case .serverError(let message):
                        "Server error: \(message)"
                    case .networkError(let underlying):
                        "Network error: \(underlying.localizedDescription)"
                    case .invalidResponse:
                        "Invalid response from server"
                    case .invalidParameters(let message):
                        "Invalid parameters: \(message)"
                    case .decodingError(let error):
                        "Error decoding response: \(error.localizedDescription)"
                    case .unexpectedStatusCode(let code):
                        "Unexpected status code: \(code)"
                    case .cancelled:
                        "Cancelled"
                    case .fileError(_):
                        "File error"
                    }
                    print("\(TerminalStyle.neonPink)\(errorMessage)\(TerminalStyle.reset)")
                }
            }
        }
    }
}
