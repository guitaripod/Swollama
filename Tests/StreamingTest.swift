import Foundation
import Swollama

@main
struct StreamingTest {
    static func main() async throws {
        print("🚀 Testing Ollama streaming...")

        let client = OllamaClient(configuration: .default)

        let model = OllamaModelName(namespace: nil, name: "llama2", tag: "latest")
        let messages = [
            ChatMessage(role: .user, content: "Count from 1 to 5 slowly, one number at a time")
        ]

        print("\n📝 Sending message to model: \(model.fullName)")
        print("Message: \(messages[0].content)")
        print("\n🔄 Streaming response:")
        print("---")

        do {
            let stream = try await client.chat(
                messages: messages,
                model: model,
                options: .default
            )

            var chunkCount = 0
            var totalContent = ""

            for try await response in stream {
                chunkCount += 1
                if !response.message.content.isEmpty {
                    print(response.message.content, terminator: "")
                    fflush(stdout)
                    totalContent += response.message.content
                }

                if response.done {
                    print("\n---")
                    print("✅ Stream completed")
                    print("📊 Statistics:")
                    print("  - Total chunks: \(chunkCount)")
                    print("  - Total content length: \(totalContent.count)")
                }
            }
        } catch {
            print("\n❌ Error: \(error)")
            if let ollamaError = error as? OllamaError {
                print("Ollama Error Type: \(ollamaError)")
            }
        }
    }
}
