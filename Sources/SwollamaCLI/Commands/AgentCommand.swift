import Foundation
import Swollama

struct AgentCommand: CommandProtocol {
    func execute(with args: [String]) async throws {
        guard !args.isEmpty else {
            print("Usage: agent <query>")
            print()
            print("Run an agentic workflow with web search capabilities.")
            print()
            print("The agent will use the qwen3:4b model to research your query")
            print("using web search and web fetch tools.")
            print()
            print("Environment Variables:")
            print("  OLLAMA_API_KEY - Required. Your Ollama API key for web search.")
            print()
            print("Example:")
            print("  export OLLAMA_API_KEY=your_key_here")
            print("  swift run SwollamaCLI agent \"what is ollama's new engine\"")
            throw CLIError.invalidArgument("Missing query argument")
        }

        guard let apiKey = ProcessInfo.processInfo.environment["OLLAMA_API_KEY"] else {
            print("Error: OLLAMA_API_KEY environment variable is not set.")
            print()
            print("To use the agent command, you need an Ollama API key.")
            print("Get one at: https://ollama.com/settings/keys")
            print()
            print("Then set it:")
            print("  export OLLAMA_API_KEY=your_key_here")
            throw CLIError.invalidArgument("OLLAMA_API_KEY not set")
        }

        let query = args.joined(separator: " ")

        guard let model = OllamaModelName.parse("qwen3:4b") else {
            throw CLIError.invalidArgument("Failed to parse model name")
        }

        print("🤖 Agent Query: \(query)")
        print("📦 Model: qwen3:4b")
        print()

        let agent = OllamaAgent(webSearchAPIKey: apiKey)

        for try await event in agent.run(prompt: query, model: model) {
            switch event {
            case .thinking(let text):
                print("🧠 Thinking:")
                print(wrapText(text, prefix: "   "))
                print()

            case .toolCall(let name, let argsJSON):
                print("🔧 Tool Call: \(name)")
                if let argsData = argsJSON.data(using: .utf8),
                    let args = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any]
                {
                    if let query = args["query"] as? String {
                        print("   Query: \(query)")
                    }
                    if let url = args["url"] as? String {
                        print("   URL: \(url)")
                    }
                    if let maxResults = args["max_results"] as? Int {
                        print("   Max Results: \(maxResults)")
                    }
                }
                print()

            case .toolResult(let name, let content):
                let preview = String(content.prefix(200))
                    .replacingOccurrences(of: "\n", with: " ")
                print("📊 Tool Result (\(name)):")
                print("   \(preview)...")
                print()

            case .message(let text):
                print("💬 Answer:")
                print(wrapText(text, prefix: "   "))
                print()

            case .done:
                print("✅ Done")
            }
        }
    }

    private func wrapText(_ text: String, prefix: String = "", width: Int = 80) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []

        for line in lines {
            if line.isEmpty {
                result.append(prefix)
                continue
            }

            var currentLine = ""
            let words = line.components(separatedBy: .whitespaces)

            for word in words {
                let testLine = currentLine.isEmpty ? word : currentLine + " " + word
                if testLine.count + prefix.count <= width {
                    currentLine = testLine
                } else {
                    if !currentLine.isEmpty {
                        result.append(prefix + currentLine)
                    }
                    currentLine = word
                }
            }

            if !currentLine.isEmpty {
                result.append(prefix + currentLine)
            }
        }

        return result.joined(separator: "\n")
    }
}
