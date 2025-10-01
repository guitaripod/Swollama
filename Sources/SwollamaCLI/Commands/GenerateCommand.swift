import Foundation
import Swollama

struct GenerateCommand: CommandProtocol {
    private let client: OllamaProtocol
    private let dateFormatter: DateFormatter

    init(client: OllamaProtocol) {
        self.client = client

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm:ss"
    }

    private func printHeader(model: OllamaModelName) {
        print("\n\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)╔════════════════════════════════════════╗\(TerminalStyle.reset)")
        print("\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)║\(TerminalStyle.neonPink) Text Generation: \(TerminalStyle.neonGreen)\(model.fullName)\(TerminalStyle.neonBlue) ║\(TerminalStyle.reset)")
        print("\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)╚════════════════════════════════════════╝\(TerminalStyle.reset)\n")

        print("\(TerminalStyle.mutedPurple)Available Commands:")
        print("• Type '\(TerminalStyle.neonYellow)exit\(TerminalStyle.mutedPurple)' or '\(TerminalStyle.neonYellow)quit\(TerminalStyle.mutedPurple)' to end the session")
        print("• Type '\(TerminalStyle.neonYellow)clear\(TerminalStyle.mutedPurple)' to clear the screen")
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

        var systemPrompt: String?

        while true {
            printTimestamp()
            print("\(TerminalStyle.neonGreen)Prompt:\(TerminalStyle.reset) ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                break
            }

            switch input.lowercased() {
            case "exit", "quit":
                print("\n\(TerminalStyle.neonPink)Goodbye! Generation session ended.\(TerminalStyle.reset)")
                return
            case "clear":
                clearScreen()
                printHeader(model: model)
                continue
            case "":
                continue
            default:
                if input.starts(with: "/system ") {
                    systemPrompt = String(input.dropFirst(8))
                    print("\n\(TerminalStyle.neonYellow)System prompt updated.\(TerminalStyle.reset)")
                    continue
                }
            }

            printTimestamp()
            print("\(TerminalStyle.neonBlue)Generated:\(TerminalStyle.reset) ", terminator: "")
            fflush(stdout)

            guard let client = client as? OllamaClient else {
                print("\(TerminalStyle.neonPink)Error: Generation requires OllamaClient\(TerminalStyle.reset)")
                return
            }

            do {
                let options = GenerationOptions(
                    systemPrompt: systemPrompt
                )

                let stream = try await client.generateText(
                    prompt: input,
                    model: model,
                    options: options
                )

                var fullResponse = ""

                for try await response in stream {
                    if !response.response.isEmpty {
                        let content = response.response
                        print(content, terminator: "")
                        fflush(stdout)
                        fullResponse += content
                    }
                }

                print("\n\(TerminalStyle.neonBlue)────────────────────────────────────────────\(TerminalStyle.reset)")

            } catch {
                print("\n\(TerminalStyle.neonPink)Error during generation: \(error)\(TerminalStyle.reset)")
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
                    case .httpError(let statusCode, let message):
                        if let message = message {
                            "HTTP error \(statusCode): \(message)"
                        } else {
                            "HTTP error \(statusCode)"
                        }
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
