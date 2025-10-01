import Foundation
import Swollama

enum EnhancedTerminalStyle {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let italic = "\u{001B}[3m"
    static let underline = "\u{001B}[4m"
    static let blink = "\u{001B}[5m"

    static let neonPink = "\u{001B}[38;2;255;20;147m"
    static let neonBlue = "\u{001B}[38;2;0;255;255m"
    static let neonGreen = "\u{001B}[38;2;0;255;127m"
    static let neonYellow = "\u{001B}[38;2;255;215;0m"
    static let mutedPurple = "\u{001B}[38;2;147;112;219m"
    static let orange = "\u{001B}[38;2;255;165;0m"
    static let red = "\u{001B}[38;2;255;69;0m"
    static let white = "\u{001B}[38;2;255;255;255m"
    static let gray = "\u{001B}[38;2;169;169;169m"

    static let bgDark = "\u{001B}[48;2;25;25;35m"
    static let bgSuccess = "\u{001B}[48;2;0;100;0m"
    static let bgError = "\u{001B}[48;2;139;0;0m"
    static let bgWarning = "\u{001B}[48;2;255;140;0m"
}

struct ChatConfiguration {
    var autoSave: Bool = false
    var savePath: String? = nil
    var showTokenCount: Bool = true
    var showTimestamps: Bool = true
    var enableMarkdown: Bool = false
    var maxContextTokens: Int = 4096
    var streamingIndicator: String = "▌"
    var typingDelay: TimeInterval = 0.0
}

enum CommandResult {
    case `continue`
    case exit
    case error(String)
}

class EnhancedChatCommand: CommandProtocol {
    private let client: OllamaProtocol
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private var configuration = ChatConfiguration()

    init(client: OllamaProtocol) {
        self.client = client

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        self.timeFormatter = DateFormatter()
        self.timeFormatter.dateFormat = "HH:mm:ss"
    }

    private func printHeader(model: OllamaModelName) {
        let width = 60
        let modelText = " Model: \(model.fullName) "
        let padding = (width - modelText.count - 2) / 2
        let leftPad = String(repeating: "═", count: padding)
        let rightPad = String(repeating: "═", count: width - modelText.count - 2 - padding)

        print(
            "\n\(EnhancedTerminalStyle.neonBlue)╔\(String(repeating: "═", count: width))╗\(EnhancedTerminalStyle.reset)"
        )
        print(
            "\(EnhancedTerminalStyle.neonBlue)║\(EnhancedTerminalStyle.neonPink)\(String(repeating: " ", count: width))\(EnhancedTerminalStyle.neonBlue)║\(EnhancedTerminalStyle.reset)"
        )
        print(
            "\(EnhancedTerminalStyle.neonBlue)║\(EnhancedTerminalStyle.neonPink)\(leftPad)\(EnhancedTerminalStyle.neonGreen)\(modelText)\(EnhancedTerminalStyle.neonPink)\(rightPad)\(EnhancedTerminalStyle.neonBlue)║\(EnhancedTerminalStyle.reset)"
        )
        print(
            "\(EnhancedTerminalStyle.neonBlue)║\(EnhancedTerminalStyle.neonPink)\(String(repeating: " ", count: width))\(EnhancedTerminalStyle.neonBlue)║\(EnhancedTerminalStyle.reset)"
        )
        print(
            "\(EnhancedTerminalStyle.neonBlue)╚\(String(repeating: "═", count: width))╝\(EnhancedTerminalStyle.reset)\n"
        )

        printCommands()
    }

    private func printCommands() {
        print(
            "\(EnhancedTerminalStyle.mutedPurple)Available Commands:\(EnhancedTerminalStyle.reset)"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/exit, /quit\(EnhancedTerminalStyle.gray) - End conversation"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/clear\(EnhancedTerminalStyle.gray) - Clear conversation history"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/save [filename]\(EnhancedTerminalStyle.gray) - Save conversation"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/load [filename]\(EnhancedTerminalStyle.gray) - Load conversation"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/system <message>\(EnhancedTerminalStyle.gray) - Set system message"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/model <name>\(EnhancedTerminalStyle.gray) - Switch model"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/retry\(EnhancedTerminalStyle.gray) - Retry last message"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/undo\(EnhancedTerminalStyle.gray) - Remove last exchange"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/tokens\(EnhancedTerminalStyle.gray) - Toggle token count display"
        )
        print(
            "  \(EnhancedTerminalStyle.neonYellow)/help\(EnhancedTerminalStyle.gray) - Show this help"
        )
        print(
            "\(EnhancedTerminalStyle.neonBlue)═══════════════════════════════════════════════════════════\(EnhancedTerminalStyle.reset)\n"
        )
    }

    private func printTimestamp() {
        guard configuration.showTimestamps else { return }
        let timestamp = timeFormatter.string(from: Date())
        print(
            "\(EnhancedTerminalStyle.dim)[\(timestamp)]\(EnhancedTerminalStyle.reset) ",
            terminator: ""
        )
    }

    private func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }

    private func printError(_ message: String) {
        print(
            "\n\(EnhancedTerminalStyle.bgError)\(EnhancedTerminalStyle.white) ERROR \(EnhancedTerminalStyle.reset) \(EnhancedTerminalStyle.red)\(message)\(EnhancedTerminalStyle.reset)"
        )
    }

    private func printSuccess(_ message: String) {
        print(
            "\n\(EnhancedTerminalStyle.bgSuccess)\(EnhancedTerminalStyle.white) SUCCESS \(EnhancedTerminalStyle.reset) \(EnhancedTerminalStyle.neonGreen)\(message)\(EnhancedTerminalStyle.reset)"
        )
    }

    private func printWarning(_ message: String) {
        print(
            "\n\(EnhancedTerminalStyle.bgWarning)\(EnhancedTerminalStyle.white) WARNING \(EnhancedTerminalStyle.reset) \(EnhancedTerminalStyle.orange)\(message)\(EnhancedTerminalStyle.reset)"
        )
    }

    private func printTypingIndicator() {
        print(
            "\(EnhancedTerminalStyle.dim)\(configuration.streamingIndicator)\(EnhancedTerminalStyle.reset)",
            terminator: ""
        )
        fflush(stdout)

        print("\r", terminator: "")
    }

    private func processCommand(
        _ input: String,
        messages: inout [ChatMessage],
        model: inout OllamaModelName
    ) -> CommandResult {
        let parts = input.split(separator: " ", maxSplits: 1)
        guard !parts.isEmpty else { return .continue }

        let command = String(parts[0]).lowercased()
        let argument = parts.count > 1 ? String(parts[1]) : ""

        switch command {
        case "/exit", "/quit":
            return .exit

        case "/clear":
            clearScreen()
            printHeader(model: model)
            messages.removeAll()
            printSuccess("Conversation cleared")
            return .continue

        case "/help":
            printCommands()
            return .continue

        case "/system":
            guard !argument.isEmpty else {
                printError("System message cannot be empty")
                return .continue
            }
            messages = messages.filter { $0.role != .system }
            messages.insert(ChatMessage(role: .system, content: argument), at: 0)
            printSuccess("System message updated")
            return .continue

        case "/save":
            return saveConversation(messages: messages, filename: argument)

        case "/load":
            return loadConversation(messages: &messages, filename: argument)

        case "/model":
            guard !argument.isEmpty else {
                printError("Model name required")
                return .continue
            }
            guard let newModel = OllamaModelName.parse(argument) else {
                printError("Invalid model name format: \(argument)")
                return .continue
            }
            model = newModel
            clearScreen()
            printHeader(model: model)
            printSuccess("Switched to model: \(model.fullName)")
            return .continue

        case "/retry":
            guard messages.count >= 2 else {
                printError("No previous message to retry")
                return .continue
            }

            if messages.last?.role == .assistant {
                messages.removeLast()
            }
            return .continue

        case "/undo":
            guard messages.count >= 2 else {
                printError("No messages to undo")
                return .continue
            }

            if messages.last?.role == .assistant {
                messages.removeLast()
            }
            if messages.last?.role == .user {
                messages.removeLast()
            }
            printSuccess("Last exchange removed")
            return .continue

        case "/tokens":
            configuration.showTokenCount.toggle()
            printSuccess("Token counting \(configuration.showTokenCount ? "enabled" : "disabled")")
            return .continue

        default:
            printError("Unknown command: \(command)")
            return .continue
        }
    }

    private func saveConversation(messages: [ChatMessage], filename: String) -> CommandResult {
        let actualFilename =
            filename.isEmpty ? "chat_\(Date().timeIntervalSince1970).json" : filename
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(messages)
            let url = URL(fileURLWithPath: actualFilename)
            try data.write(to: url)
            printSuccess("Conversation saved to: \(actualFilename)")
        } catch {
            printError("Failed to save conversation: \(error.localizedDescription)")
        }

        return .continue
    }

    private func loadConversation(messages: inout [ChatMessage], filename: String) -> CommandResult
    {
        guard !filename.isEmpty else {
            printError("Filename required")
            return .continue
        }

        do {
            let url = URL(fileURLWithPath: filename)
            let data = try Data(contentsOf: url)
            let loadedMessages = try JSONDecoder().decode([ChatMessage].self, from: data)
            messages = loadedMessages
            printSuccess("Loaded \(messages.count) messages from: \(filename)")
        } catch {
            printError("Failed to load conversation: \(error.localizedDescription)")
        }

        return .continue
    }

    private func estimateTokens(for text: String) -> Int {

        return text.count / 4
    }

    private func printTokenInfo(messages: [ChatMessage]) {
        guard configuration.showTokenCount else { return }

        let totalTokens = messages.reduce(0) { sum, message in
            sum + estimateTokens(for: message.content)
        }

        let percentage = Double(totalTokens) / Double(configuration.maxContextTokens) * 100
        let color =
            percentage > 90
            ? EnhancedTerminalStyle.red
            : percentage > 70 ? EnhancedTerminalStyle.orange : EnhancedTerminalStyle.gray

        print(
            "\(color)[Tokens: ~\(totalTokens)/\(configuration.maxContextTokens) (\(Int(percentage))%)]\(EnhancedTerminalStyle.reset)"
        )
    }

    private func handleUserInput(model: inout OllamaModelName, messages: inout [ChatMessage]) async
        -> Bool
    {
        printTimestamp()
        print(
            "\(EnhancedTerminalStyle.neonGreen)You:\(EnhancedTerminalStyle.reset) ",
            terminator: ""
        )

        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }

        guard !input.isEmpty else {
            return true
        }

        if input.starts(with: "/") {
            switch processCommand(input, messages: &messages, model: &model) {
            case .exit:
                print(
                    "\n\(EnhancedTerminalStyle.neonPink)Goodbye! Chat session ended.\(EnhancedTerminalStyle.reset)"
                )
                return false
            case .continue:
                return true
            case .error(let message):
                printError(message)
                return true
            }
        }

        messages.append(ChatMessage(role: .user, content: input))

        await generateResponse(messages: &messages, model: model)

        return true
    }

    private func generateResponse(messages: inout [ChatMessage], model: OllamaModelName) async {
        printTimestamp()
        print(
            "\(EnhancedTerminalStyle.neonBlue)Assistant:\(EnhancedTerminalStyle.reset) ",
            terminator: ""
        )
        fflush(stdout)

        guard let client = client as? OllamaClient else {
            printError("Chat functionality requires OllamaClient")
            return
        }

        do {
            let startTime = Date()
            var fullResponse = ""
            var tokenCount = 0

            if configuration.typingDelay > 0 {
                printTypingIndicator()
                try await Task.sleep(nanoseconds: UInt64(configuration.typingDelay * 1_000_000_000))
            }

            let stream = try await client.chat(
                messages: messages,
                model: model,
                options: .default
            )

            for try await response in stream {
                if !response.message.content.isEmpty {
                    let content = response.message.content
                    print(content, terminator: "")
                    fflush(stdout)
                    fullResponse += content
                    tokenCount += 1
                }

                if response.done {
                    messages.append(ChatMessage(role: .assistant, content: fullResponse))

                    if configuration.showTokenCount {
                        let duration = Date().timeIntervalSince(startTime)
                        let tokensPerSecond = Double(tokenCount) / duration
                        print(
                            "\n\(EnhancedTerminalStyle.dim)[Generated \(tokenCount) tokens in \(String(format: "%.1f", duration))s (\(String(format: "%.1f", tokensPerSecond)) tokens/s)]\(EnhancedTerminalStyle.reset)"
                        )
                    }
                }
            }

            print(
                "\n\(EnhancedTerminalStyle.neonBlue)────────────────────────────────────────────────────────────\(EnhancedTerminalStyle.reset)"
            )

            printTokenInfo(messages: messages)

        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        print()

        if let ollamaError = error as? OllamaError {
            switch ollamaError {
            case .modelNotFound:
                printError("Model not found. Use 'swollama list' to see available models.")
            case .serverError(let message):
                printError("Server error: \(message)")
            case .networkError(let underlying):
                printError("Network error: \(underlying.localizedDescription)")
                printWarning("Check if Ollama is running: 'ollama serve'")
            case .invalidResponse:
                printError("Invalid response from server")
            case .invalidParameters(let message):
                printError("Invalid parameters: \(message)")
            case .decodingError(let error):
                printError("Error decoding response: \(error.localizedDescription)")
            case .unexpectedStatusCode(let code):
                printError("Unexpected status code: \(code)")
            case .httpError(let statusCode, let message):
                if let message = message {
                    printError("HTTP error \(statusCode): \(message)")
                } else {
                    printError("HTTP error \(statusCode)")
                }
            case .cancelled:
                printWarning("Request cancelled")
            case .fileError(let message):
                printError("File error: \(message)")
            }
        } else {
            printError("Unexpected error: \(error.localizedDescription)")
        }
    }

    func execute(with arguments: [String]) async throws {
        guard !arguments.isEmpty else {
            throw CLIError.missingArgument("Model name required. Usage: swollama chat <model>")
        }

        guard var model = OllamaModelName.parse(arguments[0]) else {
            throw CLIError.invalidArgument("Invalid model name format: '\(arguments[0])'")
        }

        for i in 1..<arguments.count {
            switch arguments[i] {
            case "--no-timestamps":
                configuration.showTimestamps = false
            case "--no-tokens":
                configuration.showTokenCount = false
            case "--markdown":
                configuration.enableMarkdown = true
            case "--auto-save":
                configuration.autoSave = true
                if i + 1 < arguments.count && !arguments[i + 1].starts(with: "--") {
                    configuration.savePath = arguments[i + 1]
                }
            default:
                break
            }
        }

        clearScreen()
        printHeader(model: model)

        var messages: [ChatMessage] = []

        installSignalHandlers()

        while await handleUserInput(model: &model, messages: &messages) {

        }

        if configuration.autoSave {
            let filename = configuration.savePath ?? "chat_\(Date().timeIntervalSince1970).json"
            _ = saveConversation(messages: messages, filename: filename)
        }
    }

    private func installSignalHandlers() {
        #if os(Linux)
            signal(SIGINT) { _ in
                print(
                    "\n\(EnhancedTerminalStyle.neonPink)Chat interrupted. Type '/exit' to quit.\(EnhancedTerminalStyle.reset)"
                )
            }
        #endif
    }
}
