# Swollama

<img src="https://github.com/user-attachments/assets/bcad3675-5c0f-47aa-b4d2-ff2ebec54437" alt="swollama-logo-small" width="256" height="256" />

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fguitaripod%2FSwollama%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/guitaripod/Swollama)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fguitaripod%2FSwollama%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/guitaripod/Swollama)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://guitaripod.github.io/Swollama/documentation/swollama/)
![License](https://img.shields.io/badge/License-GPL--v3-blue)

A comprehensive, protocol-oriented Swift client for the Ollama API. This package provides a type-safe way to interact with Ollama's machine learning models, supporting all API endpoints with native Swift concurrency.

## Features

- Autonomous agents with web search capabilities
- Full Ollama API coverage (chat, generation, embeddings, model management)
- Native async/await and AsyncSequence support
- Type-safe API with comprehensive error handling
- Thread-safe implementation using Swift actors
- Automatic retry logic with exponential backoff
- Cross-platform (macOS, Linux, iOS)
- Zero external dependencies

## Requirements

- macOS 14+ / iOS 17+ / Linux
- Swift 5.9+
- [Ollama](https://ollama.ai) installed and running

## Installation

### Swift Package Manager

Add Swollama to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/guitaripod/Swollama.git", from: "1.0.0")
]
```

Or add via Xcode: File > Add Package Dependencies > `https://github.com/guitaripod/Swollama.git`

## Quick Start

### Autonomous Agent with Web Search

```swift
import Swollama

let agent = OllamaAgent(webSearchAPIKey: "your_ollama_api_key")
guard let model = OllamaModelName.parse("qwen2.5:3b") else { fatalError() }

for try await event in agent.run(
    prompt: "What are the latest features in Swift 6?",
    model: model
) {
    switch event {
    case .thinking(let thought):
        print("Thinking: \(thought)")
    case .toolCall(let name, _):
        print("Using tool: \(name)")
    case .message(let answer):
        print("Answer: \(answer)")
    case .done:
        print("Complete")
    default:
        break
    }
}
```

### Chat Completion

```swift
import Swollama

let client = OllamaClient()
guard let model = OllamaModelName.parse("llama3.2") else { fatalError() }

let responses = try await client.chat(
    messages: [
        ChatMessage(role: .user, content: "Hello! How are you?")
    ],
    model: model
)

for try await response in responses {
    print(response.message.content, terminator: "")
}
```

## CLI Usage

Interactive chat:
```bash
swollama chat llama3.2
```

Autonomous agent:
```bash
swollama agent qwen2.5:3b --prompt "What's new in Swift?"
```

Generate text:
```bash
swollama generate codellama
```

Model management:
```bash
swollama pull llama3.2
swollama list
swollama show llama3.2
swollama delete old-model
```

## Documentation

Complete API documentation, examples, and feature guides:
- [API Reference](https://guitaripod.github.io/Swollama/documentation/swollama/)
- [Feature Guide](FEATURES.md)

## Examples

### Text Generation with Options

```swift
let client = OllamaClient()
guard let model = OllamaModelName.parse("llama3.2") else { fatalError() }

let stream = try await client.generateText(
    prompt: "Explain quantum computing",
    model: model,
    options: GenerationOptions(
        temperature: 0.7,
        topP: 0.9,
        numPredict: 200
    )
)

for try await response in stream {
    print(response.response, terminator: "")
}
```

### Embeddings

```swift
let client = OllamaClient()
guard let model = OllamaModelName.parse("nomic-embed-text") else { fatalError() }

let response = try await client.generateEmbeddings(
    input: .single("Hello world"),
    model: model
)

print("Vector dimensions: \(response.embeddings[0].count)")
```

### Tool Calling

```swift
let tools = [
    ToolDefinition(
        type: "function",
        function: FunctionDefinition(
            name: "get_weather",
            description: "Get current weather",
            parameters: JSONSchema(
                type: "object",
                properties: [
                    "location": JSONSchemaProperty(type: "string")
                ],
                required: ["location"]
            )
        )
    )
]

let stream = try await client.chat(
    messages: [ChatMessage(role: .user, content: "What's the weather in Paris?")],
    model: OllamaModelName.parse("llama3.2")!,
    options: ChatOptions(tools: tools)
)

for try await response in stream {
    if let toolCalls = response.message.toolCalls {
        for call in toolCalls {
            print("Tool: \(call.function.name)")
            print("Args: \(call.function.arguments)")
        }
    }
}
```

## Contributing

Contributions are welcome. Please open an issue first to discuss major changes.

## License

GPL-v3
