import Foundation
import Swollama

struct DeleteModelCommand: CommandProtocol {
    private let client: OllamaProtocol

    init(client: OllamaProtocol) {
        self.client = client
    }

    func execute(with arguments: [String]) async throws {
        guard !arguments.isEmpty else {
            throw CLIError.missingArgument("Model name required")
        }

        guard let model = OllamaModelName.parse(arguments[0]) else {
            throw CLIError.invalidArgument("Invalid model name format")
        }

        print("Are you sure you want to delete model: \(model.fullName)? (y/N)")
        guard let response = readLine()?.lowercased(),
            response == "y" || response == "yes"
        else {
            print("Operation cancelled.")
            return
        }

        print("Deleting model...")
        try await client.deleteModel(name: model)
        print("\n\u{1B}[32m✨ Model deleted successfully!\u{1B}[0m")
    }
}
