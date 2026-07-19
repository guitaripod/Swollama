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

        let verbose = arguments.contains("--verbose") || arguments.contains("-v")

        print("Fetching details for model: \(model.fullName)...")
        let info = try await client.showModel(name: model, verbose: verbose ? true : nil)

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
        if let remoteModel = info.remoteModel {
            print("  Remote Model: \(remoteModel)")
        }
        if let remoteHost = info.remoteHost {
            print("  Remote Host: \(remoteHost)")
        }
        if let system = info.system, !system.isEmpty {
            print("  System: \(truncate(system, to: 100))")
        }
        if let renderer = info.renderer {
            print("  Renderer: \(renderer)")
        }
        if let parser = info.parser {
            print("  Parser: \(parser)")
        }
        if let license = info.license, !license.isEmpty {
            print("  License: \(truncate(firstLine(license), to: 80))")
        }
        if let arch = info.modelInfo?["general.architecture"]?.stringValue {
            print("  Architecture: \(arch)")
        }

        if let modelInfo = info.modelInfo {
            if verbose {
                print("\nModel Info (\(modelInfo.count) keys):")
                for key in modelInfo.keys.sorted() {
                    print("  \(key): \(describe(modelInfo[key]))")
                }
            } else {
                print("  Model Info Keys: \(modelInfo.count)")
            }
        }

        if let tensors = info.tensors {
            if verbose {
                print("\nTensors (\(formatNumber(tensors.count))):")
                for tensor in tensors.prefix(20) {
                    let shape = tensor.shape.map(String.init).joined(separator: "x")
                    print("  \(tensor.name) [\(tensor.type)] \(shape)")
                }
                if tensors.count > 20 {
                    print("  ... and \(formatNumber(tensors.count - 20)) more")
                }
            } else {
                print("  Tensors: \(formatNumber(tensors.count))")
            }
        }

        if !verbose {
            print("\nRe-run with --verbose for full model_info and tensor listings.")
        }
    }

    private func describe(_ value: JSONValue?) -> String {
        guard let value else { return "null" }
        switch value {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        case .array(let a): return "[\(a.count) items]"
        case .object(let o): return "{\(o.count) keys}"
        case .null: return "null"
        }
    }

    private func firstLine(_ text: String) -> String {
        text.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? text
    }

    private func truncate(_ text: String, to length: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > length ? String(trimmed.prefix(length)) + "…" : trimmed
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }
}
