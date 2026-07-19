import Foundation
import Swollama

struct ShowModelCommand: CommandProtocol {
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

        print("Fetching details for model: \(model.fullName)...")
        let info = try await client.showModel(name: model, verbose: nil)

        print("\nModel Details:")
        print("--------------")
        print("Properties:")
        print("  Format: \(info.details.format)")
        print("  Family: \(info.details.family)")
        if let families = info.details.families {
            print("  All Families: \(families.joined(separator: ", "))")
        }
        print("  Parameter Size: \(info.details.parameterSize)")
        print("  Quantization: \(info.details.quantizationLevel)")
        if let contextLength = info.details.contextLength {
            print("  Context Length: \(formatNumber(contextLength))")
        }
        if let embeddingLength = info.details.embeddingLength {
            print("  Embedding Length: \(formatNumber(embeddingLength))")
        }

        if let capabilities = info.capabilities, !capabilities.isEmpty {
            print("  Capabilities: \(capabilities.map(\.rawValue).joined(separator: ", "))")
        }
        if let requires = info.requires {
            print("  Requires Ollama: \(requires)")
        }
        if let arch = info.modelInfo?["general.architecture"]?.stringValue {
            print("  Architecture: \(arch)")
        }
        if let modelInfo = info.modelInfo {
            print("  Model Info Keys: \(modelInfo.count)")
        }
        if let tensors = info.tensors {
            print("  Tensors: \(formatNumber(tensors.count))")
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }
}
