import Foundation
import Swollama

struct ListModelsCommand: CommandProtocol {
    private let client: OllamaProtocol
    private let formatter: ModelFormatter

    init(client: OllamaProtocol, formatter: ModelFormatter = DefaultModelFormatter()) {
        self.client = client
        self.formatter = formatter
    }

    func execute(with arguments: [String]) async throws {
        print("Fetching available models...")
        let models = try await client.listModels()
            .sorted { $0.name.lowercased() < $1.name.lowercased() }

        print("\nAvailable Models:")
        print("----------------")
        for model in models {
            print(formatter.format(model))
        }
    }
}
