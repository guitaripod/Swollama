import Foundation
import Swollama

struct VersionCommand: CommandProtocol {
    private let client: OllamaProtocol

    init(client: OllamaProtocol) {
        self.client = client
    }

    func execute(with arguments: [String]) async throws {
        print("Checking Ollama server version...\n")

        do {
            let version = try await client.getVersion()
            print("✅ Ollama version: \(version.version)")
        } catch {
            print("❌ Failed to get version: \(error)")
            throw error
        }
    }
}
