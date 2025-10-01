import Foundation
import Swollama

struct EmbeddingsCommand: CommandProtocol {
    private let client: OllamaProtocol

    init(client: OllamaProtocol) {
        self.client = client
    }

    func execute(with arguments: [String]) async throws {
        guard arguments.count >= 1 else {
            throw CLIError.missingArgument("text or texts to embed")
        }

        var modelName = "all-minilm"
        var truncate = true
        var outputFormat = OutputFormat.json
        var inputTexts: [String] = []

        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--model", "-m":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--model requires a model name")
                }
                modelName = arguments[i]

            case "--no-truncate":
                truncate = false

            case "--format", "-f":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--format requires a format (json, csv, raw)")
                }
                guard let format = OutputFormat(rawValue: arguments[i]) else {
                    throw CLIError.invalidArgument("Invalid format. Valid options: json, csv, raw")
                }
                outputFormat = format

            case "--help", "-h":
                printEmbeddingsHelp()
                return

            default:

                if !arguments[i].starts(with: "--") && !arguments[i].starts(with: "-") {
                    inputTexts.append(arguments[i])
                }
            }
            i += 1
        }

        guard !inputTexts.isEmpty else {
            throw CLIError.missingArgument("No text provided to embed")
        }

        guard let model = OllamaModelName.parse(modelName) else {
            throw CLIError.invalidArgument("Invalid model name format")
        }

        let options = EmbeddingOptions(truncate: truncate)

        print("Generating embeddings using model '\(modelName)'...")
        print("Input texts: \(inputTexts.count)")
        print("")

        do {

            guard let ollamaClient = client as? OllamaClient else {
                throw CLIError.invalidArgument("Client does not support embeddings generation")
            }

            let response = try await ollamaClient.generateEmbeddings(
                input: inputTexts.count == 1 ? .single(inputTexts[0]) : .multiple(inputTexts),
                model: model,
                options: options
            )

            outputFormat.display(response)

        } catch {
            print("❌ Failed to generate embeddings: \(error)")
            throw error
        }
    }

    private func printEmbeddingsHelp() {
        print(
            """
            Usage: swollama embeddings <text1> [text2 ...] [options]

            Generate embeddings for one or more texts.

            Options:
                --model, -m <model>     Model to use (default: all-minilm)
                --no-truncate           Don't truncate inputs
                --format, -f <format>   Output format: json, csv, raw (default: json)
                --help, -h              Show this help message

            Examples:
                # Generate embeddings for a single text
                swollama embeddings "Why is the sky blue?"

                # Generate embeddings for multiple texts
                swollama embeddings "Hello world" "How are you?" "Goodbye"

                # Use a specific model
                swollama embeddings "Test text" --model mxbai-embed-large

                # Output as CSV
                swollama embeddings "Sample text" --format csv
            """
        )
    }
}

private enum OutputFormat: String {
    case json, csv, raw

    func display(_ response: EmbeddingResponse) {
        switch self {
        case .json:
            displayJSON(response)
        case .csv:
            displayCSV(response)
        case .raw:
            displayRaw(response)
        }
    }

    private func displayJSON(_ response: EmbeddingResponse) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(response)
            if let json = String(data: data, encoding: .utf8) {
                print(json)
            }
        } catch {
            print("Error encoding to JSON: \(error)")
        }
    }

    private func displayCSV(_ response: EmbeddingResponse) {
        print("# Embeddings CSV Output")
        print("# Model: \(response.model)")
        print("# Total Duration: \(response.totalDuration ?? 0)ns")
        print("# Dimensions: \(response.embeddings.first?.count ?? 0)")
        print("")

        for (index, embedding) in response.embeddings.enumerated() {
            let values = embedding.map { String($0) }.joined(separator: ",")
            print("Embedding_\(index),\(values)")
        }
    }

    private func displayRaw(_ response: EmbeddingResponse) {
        print("Model: \(response.model)")
        print("Embeddings: \(response.embeddings.count)")
        print("Dimensions: \(response.embeddings.first?.count ?? 0)")
        print("Total Duration: \(response.totalDuration ?? 0)ns")
        print("Load Duration: \(response.loadDuration ?? 0)ns")
        print("Prompt Eval Count: \(response.promptEvalCount ?? 0)")
        print("")

        for (index, embedding) in response.embeddings.enumerated() {
            print("Embedding \(index):")
            print(
                "First 10 values: \(embedding.prefix(10).map { String(format: "%.6f", $0) }.joined(separator: ", "))"
            )
            print("")
        }
    }
}
