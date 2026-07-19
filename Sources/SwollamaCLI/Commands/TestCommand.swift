import Foundation
import Swollama

struct TestCommand: CommandProtocol {
    private let client: OllamaProtocol

    init(client: OllamaProtocol) {
        self.client = client
    }

    func execute(with arguments: [String]) async throws {
        var testType = "all"
        var modelName = "llama3.2"

        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--model", "-m":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--model requires a model name")
                }
                modelName = arguments[i]

            case "--test", "-t":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--test requires a test type")
                }
                testType = arguments[i]

            case "--help", "-h":
                printTestHelp()
                return

            default:
                if i == 0 && !arguments[i].starts(with: "-") {
                    testType = arguments[i]
                }
            }
            i += 1
        }

        guard let model = OllamaModelName.parse(modelName) else {
            throw CLIError.invalidArgument("Invalid model name format")
        }

        switch testType {
        case "structured":
            try await testStructuredOutput(model: model)
        case "thinking":
            try await testThinkingModel(model: model)
        case "json":
            try await testJSONMode(model: model)
        case "images":
            try await testImageInput(model: model)
        case "tools":
            try await testToolCalling(model: model)
        case "suffix":
            try await testSuffix(model: model)
        case "all":
            print("Running all tests...\n")
            try await testStructuredOutput(model: model)
            print("\n" + String(repeating: "=", count: 60) + "\n")
            try await testJSONMode(model: model)
            print("\n" + String(repeating: "=", count: 60) + "\n")
            try await testSuffix(model: model)
        default:
            throw CLIError.invalidArgument("Unknown test type: \(testType)")
        }
    }

    private func testStructuredOutput(model: OllamaModelName) async throws {
        print("🧪 Testing Structured Output with JSON Schema")
        print("Model: \(model.fullName)\n")

        let schema = JSONSchema(
            type: "object",
            properties: [
                "name": JSONSchemaProperty(type: "string", description: "The person's name"),
                "age": JSONSchemaProperty(type: "integer", description: "The person's age"),
                "available": JSONSchemaProperty(
                    type: "boolean",
                    description: "Whether the person is available"
                ),
                "skills": JSONSchemaProperty(
                    type: "array",
                    items: JSONSchemaProperty(type: "string")
                ),
            ],
            required: ["name", "age", "available"]
        )

        let request = GenerateRequest(
            model: model.fullName,
            prompt:
                "Tell me about a fictional software developer named Alex who is 28 years old. Include their availability and skills. Respond using JSON.",
            format: .jsonSchema(schema),
            stream: false
        )

        print("Prompt: \(request.prompt)")
        print("\nGenerating structured response...\n")

        do {
            let response = try await generateSingle(request)
            print("Response:")
            print(response.response)

            if let data = response.response.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                print("\n✅ Valid JSON with keys: \(json.keys.sorted())")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }

    private func testJSONMode(model: OllamaModelName) async throws {
        print("🧪 Testing JSON Mode")
        print("Model: \(model.fullName)\n")

        let request = GenerateRequest(
            model: model.fullName,
            prompt:
                "What are the primary colors? List them in a JSON object with a 'colors' array. Respond using JSON.",
            format: .json,
            stream: false
        )

        print("Prompt: \(request.prompt)")
        print("\nGenerating JSON response...\n")

        do {
            let response = try await generateSingle(request)
            print("Response:")
            print(response.response)

            if let data = response.response.data(using: .utf8),
                (try? JSONSerialization.jsonObject(with: data)) != nil
            {
                print("\n✅ Valid JSON response")
            } else {
                print("\n⚠️  Response may not be valid JSON")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }

    private func testThinkingModel(model: OllamaModelName) async throws {
        print("🧪 Testing Thinking Model Support")
        print("Model: \(model.fullName)\n")
        print("Note: This requires a thinking-capable model like deepseek-r1\n")

        let messages = [
            ChatMessage(
                role: .user,
                content:
                    "Can you solve this step by step: If a train travels 120 miles in 2 hours, how far will it travel in 5 hours at the same speed?"
            )
        ]

        let request = ChatRequest(
            model: model.fullName,
            messages: messages,
            stream: false,
            think: true
        )

        print("Enabling thinking mode...")
        print("User: \(messages[0].content)\n")

        do {
            let response = try await chatSingle(request)

            if let thinking = response.thinking {
                print("💭 Model's Thinking Process:")
                print(thinking)
                print("\n" + String(repeating: "-", count: 40) + "\n")
            }

            print("💬 Model's Response:")
            print(response.content)
        } catch {
            print("❌ Error: \(error)")
        }
    }

    private func testImageInput(model: OllamaModelName) async throws {
        print("🧪 Testing Image Input (Multimodal)")
        print("Model: \(model.fullName)\n")
        print("Note: This requires a multimodal model like llava\n")

        let testImageBase64 =
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

        let messages = [
            ChatMessage(
                role: .user,
                content: "What do you see in this image?",
                images: [testImageBase64]
            )
        ]

        let request = ChatRequest(
            model: model.fullName,
            messages: messages,
            stream: false
        )

        print("Sending image with question...")

        do {
            let response = try await chatSingle(request)
            print("\nResponse: \(response.content)")
        } catch {
            print("❌ Error: \(error)")
            print("(This is expected if the model doesn't support images)")
        }
    }

    private func testToolCalling(model: OllamaModelName) async throws {
        print("🧪 Testing Tool/Function Calling")
        print("Model: \(model.fullName)\n")

        let weatherTool = ToolDefinition(
            type: "function",
            function: FunctionDefinition(
                name: "get_weather",
                description: "Get the current weather for a location",
                parameters: Parameters(
                    properties: [
                        "location": PropertyDefinition(
                            type: "string",
                            description: "The city and state, e.g. San Francisco, CA"
                        ),
                        "unit": PropertyDefinition(
                            type: "string",
                            description: "The temperature unit",
                            enumValues: ["celsius", "fahrenheit"]
                        ),
                    ],
                    required: ["location"]
                )
            )
        )

        let messages = [
            ChatMessage(role: .user, content: "What's the weather like in Paris?")
        ]

        let request = ChatRequest(
            model: model.fullName,
            messages: messages,
            tools: [weatherTool],
            stream: false
        )

        print("Available tools: get_weather")
        print("User: \(messages[0].content)\n")

        do {
            let response = try await chatSingle(request)

            if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
                print("🔧 Tool Calls:")
                for call in toolCalls {
                    if let id = call.id {
                        print("  - ID: \(id)")
                    }
                    print("  - Function: \(call.function.name)")
                    print("    Arguments: \(call.function.arguments)")
                }
            } else {
                print("Response: \(response.content)")
                print("(No tool calls were made)")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }

    private func testSuffix(model: OllamaModelName) async throws {
        print("🧪 Testing Suffix Parameter (Code Completion)")
        print("Model: \(model.fullName)\n")

        let request = GenerateRequest(
            model: model.fullName,
            prompt: "def fibonacci(n):\n    if n <= 1:\n        return n\n    else:",
            suffix: "\n\n# Example usage\nprint(fibonacci(10))",
            options: ModelOptions(temperature: 0),
            stream: false
        )

        print("Prompt:")
        print(request.prompt)
        print("\nSuffix:")
        print(request.suffix ?? "")
        print("\nGenerating completion...\n")

        do {
            let response = try await generateSingle(request)
            print("Complete code:")
            print(request.prompt + response.response + (request.suffix ?? ""))
        } catch {
            print("❌ Error: \(error)")
        }
    }

    private struct GenerateResult {
        let response: String
        let thinking: String?
    }

    private struct ChatResult {
        let content: String
        let thinking: String?
        let toolCalls: [ToolCall]?
    }

    private func generateSingle(_ request: GenerateRequest) async throws -> GenerateResult {
        let options = GenerationOptions(
            suffix: request.suffix,
            images: request.images,
            format: request.format,
            modelOptions: request.options,
            systemPrompt: request.system,
            template: request.template,
            context: request.context,
            raw: request.raw,
            keepAlive: request.keepAlive,
            think: request.think
        )

        guard let modelName = OllamaModelName.parse(request.model) else {
            throw CLIError.invalidArgument("Invalid model name")
        }

        guard let ollamaClient = client as? OllamaClient else {
            throw CLIError.invalidCommand("Client must be OllamaClient to use generateText")
        }

        let stream = try await ollamaClient.generateText(
            prompt: request.prompt,
            model: modelName,
            options: options
        )

        var response = ""
        var thinking = ""
        for try await chunk in stream {
            response += chunk.response
            if let chunkThinking = chunk.thinking {
                thinking += chunkThinking
            }
        }

        return GenerateResult(
            response: response,
            thinking: thinking.isEmpty ? nil : thinking
        )
    }

    private func chatSingle(_ request: ChatRequest) async throws -> ChatResult {
        let options = ChatOptions(
            tools: request.tools,
            format: request.format,
            modelOptions: request.options,
            keepAlive: request.keepAlive,
            think: request.think
        )

        guard let modelName = OllamaModelName.parse(request.model) else {
            throw CLIError.invalidArgument("Invalid model name")
        }

        guard let ollamaClient = client as? OllamaClient else {
            throw CLIError.invalidCommand("Client must be OllamaClient to use chat")
        }

        let stream = try await ollamaClient.chat(
            messages: request.messages,
            model: modelName,
            options: options
        )

        var content = ""
        var thinking = ""
        var toolCalls: [ToolCall] = []
        for try await chunk in stream {
            content += chunk.message.content
            if let chunkThinking = chunk.message.thinking {
                thinking += chunkThinking
            }
            if let chunkToolCalls = chunk.message.toolCalls {
                toolCalls.append(contentsOf: chunkToolCalls)
            }
        }

        return ChatResult(
            content: content,
            thinking: thinking.isEmpty ? nil : thinking,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls
        )
    }

    private func printTestHelp() {
        print(
            """
            Usage: swollama test [test-type] [options]

            Test new Ollama API features.

            Test Types:
                structured    Test structured output with JSON Schema
                thinking      Test thinking model support
                json          Test JSON mode
                images        Test image input (multimodal)
                tools         Test tool/function calling
                suffix        Test suffix parameter (code completion)
                all           Run all tests (default)

            Options:
                --model, -m <model>    Model to use (default: llama3.2)
                --test, -t <type>      Test type to run
                --help, -h             Show this help message

            Examples:
                # Run all tests
                swollama test

                # Test structured output with a specific model
                swollama test structured --model llama3.1

                # Test thinking mode with deepseek-r1
                swollama test thinking --model deepseek-r1

                # Test multimodal with llava
                swollama test images --model llava
            """
        )
    }
}
