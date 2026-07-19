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
        print(
            "\n\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)╔════════════════════════════════════════╗\(TerminalStyle.reset)"
        )
        print(
            "\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)║\(TerminalStyle.neonPink) Text Generation: \(TerminalStyle.neonGreen)\(model.fullName)\(TerminalStyle.neonBlue) ║\(TerminalStyle.reset)"
        )
        print(
            "\(TerminalStyle.bgDark)\(TerminalStyle.neonBlue)╚════════════════════════════════════════╝\(TerminalStyle.reset)\n"
        )

        print("\(TerminalStyle.mutedPurple)Available Commands:")
        print(
            "• Type '\(TerminalStyle.neonYellow)exit\(TerminalStyle.mutedPurple)' or '\(TerminalStyle.neonYellow)quit\(TerminalStyle.mutedPurple)' to end the session"
        )
        print(
            "• Type '\(TerminalStyle.neonYellow)clear\(TerminalStyle.mutedPurple)' to clear the screen"
        )
        print(
            "• Type '\(TerminalStyle.neonYellow)/system <message>\(TerminalStyle.mutedPurple)' to set a system message\(TerminalStyle.reset)"
        )
        print(
            "\(TerminalStyle.neonBlue)═══════════════════════════════════════════════\(TerminalStyle.reset)\n"
        )
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

        var oneShotPrompt: String?
        var systemPrompt: String?
        var think: ThinkingMode?

        var i = 1
        while i < arguments.count {
            switch arguments[i] {
            case "--prompt", "-p":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--prompt requires text")
                }
                oneShotPrompt = arguments[i]
            case "--system", "-s":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--system requires text")
                }
                systemPrompt = arguments[i]
            case "--think":
                think = .enabled
            case "--think-level":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--think-level requires a level")
                }
                think = .level(arguments[i])
            default:
                break
            }
            i += 1
        }

        guard let client = client as? OllamaClient else {
            throw CLIError.invalidCommand("Generation requires OllamaClient")
        }

        if let prompt = oneShotPrompt {
            try await runOnce(
                prompt: prompt,
                system: systemPrompt,
                think: think,
                model: model,
                client: client
            )
            return
        }

        clearScreen()
        printHeader(model: model)

        while true {
            printTimestamp()
            print("\(TerminalStyle.neonGreen)Prompt:\(TerminalStyle.reset) ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                break
            }

            switch input.lowercased() {
            case "exit", "quit":
                print(
                    "\n\(TerminalStyle.neonPink)Goodbye! Generation session ended.\(TerminalStyle.reset)"
                )
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
                    print(
                        "\n\(TerminalStyle.neonYellow)System prompt updated.\(TerminalStyle.reset)"
                    )
                    continue
                }
            }

            printTimestamp()
            print("\(TerminalStyle.neonBlue)Generated:\(TerminalStyle.reset) ", terminator: "")
            fflush(stdout)

            do {
                _ = try await streamGeneration(
                    prompt: input,
                    system: systemPrompt,
                    think: think,
                    model: model,
                    client: client
                )
                print(
                    "\n\(TerminalStyle.neonBlue)────────────────────────────────────────────\(TerminalStyle.reset)"
                )
            } catch let ollamaError as OllamaError {
                print(
                    "\n\(TerminalStyle.neonPink)\(ollamaError.cliDescription(model: model))\(TerminalStyle.reset)"
                )
            } catch {
                print(
                    "\n\(TerminalStyle.neonPink)Error during generation: \(error.localizedDescription)\(TerminalStyle.reset)"
                )
            }
        }
    }

    /// Runs a single non-interactive generation, printing only the response to stdout (thinking, if any,
    /// goes to stderr) so the command is safe to pipe/redirect for scripting.
    private func runOnce(
        prompt: String,
        system: String?,
        think: ThinkingMode?,
        model: OllamaModelName,
        client: OllamaClient
    ) async throws {
        do {
            _ = try await streamGeneration(
                prompt: prompt,
                system: system,
                think: think,
                model: model,
                client: client,
                plain: true
            )
            print("")
        } catch let ollamaError as OllamaError {
            FileHandle.standardError.write(
                Data((ollamaError.cliDescription(model: model) + "\n").utf8)
            )
            throw ollamaError
        }
    }

    /// Streams a generation, printing thinking and response tokens as they arrive.
    /// - Parameter plain: when `true`, response goes to stdout unstyled and thinking to stderr.
    @discardableResult
    private func streamGeneration(
        prompt: String,
        system: String?,
        think: ThinkingMode?,
        model: OllamaModelName,
        client: OllamaClient,
        plain: Bool = false
    ) async throws -> String {
        let options = GenerationOptions(systemPrompt: system, think: think)
        let stream = try await client.generateText(prompt: prompt, model: model, options: options)

        var fullResponse = ""
        for try await response in stream {
            if let thinking = response.thinking, !thinking.isEmpty {
                if plain {
                    FileHandle.standardError.write(Data(thinking.utf8))
                } else {
                    print(
                        "\(TerminalStyle.mutedPurple)\(thinking)\(TerminalStyle.reset)",
                        terminator: ""
                    )
                    fflush(stdout)
                }
            }
            if !response.response.isEmpty {
                print(response.response, terminator: "")
                fflush(stdout)
                fullResponse += response.response
            }
        }
        return fullResponse
    }
}
