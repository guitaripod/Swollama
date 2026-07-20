# Swollama

<img src="https://github.com/user-attachments/assets/bcad3675-5c0f-47aa-b4d2-ff2ebec54437" alt="swollama-logo-small" width="256" height="256" />

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fguitaripod%2FSwollama%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/guitaripod/Swollama)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fguitaripod%2FSwollama%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/guitaripod/Swollama)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://guitaripod.github.io/Swollama/documentation/swollama/)
![License](https://img.shields.io/badge/License-GPL--v3-blue)

A comprehensive, protocol-oriented Swift client for the Ollama API. This package provides a type-safe way to interact with Ollama's machine learning models, supporting all API endpoints with native Swift concurrency.

## Features

- Full native Ollama API coverage — generate, chat, embeddings (`/api/embed` + legacy `/api/embeddings`), model management, blobs, `ps`, `version`
- Thinking / reasoning models, including reasoning-effort levels (`low`/`medium`/`high`)
- Structured outputs via JSON Schema (typed or arbitrary), plus JSON mode
- Tool / function calling with tool-call `id`, `tool_name`, and `tool_call_id` correlation
- Multimodal image inputs and model `capabilities` (vision, tools, thinking, embedding, insert, audio)
- Rich model introspection (`model_info`, `tensors`, `capabilities`, `context_length`, `requires`)
- Autonomous agents with web search capabilities
- Authenticated & cloud hosts via API key (`Authorization: Bearer`)
- Native async/await and AsyncSequence streaming, with non-streaming conveniences
- Type-safe API with comprehensive error handling (parses Ollama's error bodies)
- Thread-safe Swift actors; `Sendable` throughout, clean under Swift 6 strict concurrency
- Automatic retry with exponential backoff; honors HTTP 429 `Retry-After`
- Cross-platform (macOS, iOS, tvOS, watchOS, visionOS, Linux)
- Zero external dependencies

## Requirements

- macOS 14+ / iOS 17+ / tvOS 17+ / watchOS 10+ / visionOS 1+ / Linux
- Swift 5.9+ (builds clean under Swift 6 strict concurrency)
- Zero external dependencies
- [Ollama](https://ollama.ai) installed and running

## Installation

### Swift Package Manager

Add Swollama to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/guitaripod/Swollama.git", from: "4.2.0")
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

Prefer the whole answer at once? Use the non-streaming conveniences:

```swift
let text = try await client.completeText(prompt: "Name three primary colors.", model: model)
let reply = try await client.completeChat(
    messages: [ChatMessage(role: .user, content: "Say hi.")],
    model: model
)
print(reply.content)
```

### Authenticated & Cloud Hosts

Set an API key to reach an authenticated deployment or Ollama's cloud. It is sent as an
`Authorization: Bearer` header on every request, including streaming.

```swift
let client = OllamaClient(
    baseURL: URL(string: "https://ollama.example.com")!,
    configuration: OllamaConfiguration(apiKey: "your-api-key")
)
```

## CLI Usage

Interactive chat:
```bash
swollama chat llama3.2
```

One-shot chat (prints only the answer on stdout — pipeable):
```bash
swollama chat llama3.2 "Summarize the plot of Dune in one sentence"
echo "Translate 'hello' to French" | swollama chat llama3.2
```

Point at a remote or authenticated host with environment variables:
```bash
export OLLAMA_HOST=192.168.1.10:11434
export OLLAMA_API_KEY=your-api-key   # sent as Authorization: Bearer
swollama list
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
        modelOptions: ModelOptions(numPredict: 200, topP: 0.9, temperature: 0.7)
    )
)

for try await response in stream {
    print(response.response, terminator: "")
}
```

### Thinking / Reasoning

```swift
let client = OllamaClient()
guard let model = OllamaModelName.parse("qwen3") else { fatalError() }

let stream = try await client.chat(
    messages: [ChatMessage(role: .user, content: "How many r's are in strawberry?")],
    model: model,
    options: ChatOptions(think: .high)   // or `true`, `.low`, `.medium`, `.max`
)

for try await response in stream {
    if let thinking = response.message.thinking {
        print(thinking, terminator: "")   // the model's reasoning
    }
    print(response.message.content, terminator: "")
}
```

### Structured Outputs

```swift
let schema = JSONSchema(
    type: "object",
    properties: [
        "name": JSONSchemaProperty(type: "string", description: "Full name"),
        "age": JSONSchemaProperty(type: "integer")
    ],
    required: ["name", "age"]
)

let stream = try await client.chat(
    messages: [ChatMessage(role: .user, content: "Invent a developer profile as JSON.")],
    model: OllamaModelName.parse("llama3.2")!,
    options: ChatOptions(format: .jsonSchema(schema))
)
// For schemas beyond the typed builder (e.g. $defs, anyOf), use `.schema(JSONValue)`.
```

### Embeddings

```swift
let client = OllamaClient()
guard let model = OllamaModelName.parse("embeddinggemma") else { fatalError() }

let response = try await client.generateEmbeddings(
    input: .multiple(["Hello world", "How are you?"]),
    model: model,
    options: EmbeddingOptions(dimensions: 256)   // Matryoshka truncation (optional)
)

print("Vectors: \(response.embeddings.count) x \(response.embeddings[0].count)")
```

### Tool Calling

```swift
let tools = [
    ToolDefinition(
        type: "function",
        function: FunctionDefinition(
            name: "get_weather",
            description: "Get current weather",
            parameters: Parameters(
                properties: [
                    "location": PropertyDefinition(type: "string", description: "City name")
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
            print("Tool: \(call.function.name) [\(call.id ?? "-")]")
            print("Args: \(call.function.arguments)")
        }
    }
}
```

## Contributing

Contributions are welcome. Please open an issue first to discuss major changes.

## License

GPL-v3
