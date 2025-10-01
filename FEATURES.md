# Swollama Feature Documentation

Complete guide to all features in Swollama, including the latest Ollama API capabilities.

---

## 📋 Quick Navigation

- [Core Features](#-core-features)
- [API Methods](#-api-methods)
- [Advanced Features](#-advanced-features)
- [CLI Commands](#-cli-commands)
- [Platform Support](#-platform-support)

---

## ✨ Core Features

<details>
<summary><b>Structured Outputs with JSON Schema</b></summary>

Generate responses that conform to a specific JSON schema, ensuring type-safe and validated outputs.

```swift
import Swollama

let client = OllamaClient()

let schema = JSONSchema(
    type: "object",
    properties: [
        "name": JSONSchemaProperty(type: "string"),
        "age": JSONSchemaProperty(type: "integer"),
        "available": JSONSchemaProperty(type: "boolean"),
        "skills": JSONSchemaProperty(
            type: "array",
            items: JSONSchemaProperty(type: "string")
        )
    ],
    required: ["name", "age", "available"]
)

let stream = try await client.generateText(
    prompt: "Tell me about a software developer named Alex",
    model: OllamaModelName.parse("llama3.2")!,
    options: GenerationOptions(format: .jsonSchema(schema))
)

for try await response in stream {
    print(response.response)
}
```

**CLI Usage:**
```bash
swollama test structured --model llama3.2
```

</details>

<details>
<summary><b>Thinking Models (Reasoning)</b></summary>

Support for models that show their reasoning process before providing an answer.

```swift
let messages = [
    ChatMessage(role: .user, content: "Solve this step by step: What is 15 * 24?")
]

let stream = try await client.chat(
    messages: messages,
    model: OllamaModelName.parse("deepseek-r1")!,
    options: ChatOptions(think: true)
)

for try await response in stream {
    if let thinking = response.message.thinking {
        print("Thinking: \(thinking)")
    }
    print("Answer: \(response.message.content)")

    if response.done {
        if let reason = response.doneReason {
            print("Completed: \(reason)")
        }
    }
}
```

**CLI Usage:**
```bash
swollama test thinking --model deepseek-r1
```

</details>

<details>
<summary><b>Tool/Function Calling</b></summary>

Enable models to call predefined functions/tools during generation.

```swift
let tools = [
    ToolDefinition(
        type: "function",
        function: FunctionDefinition(
            name: "get_weather",
            description: "Get current weather for a location",
            parameters: JSONSchema(
                type: "object",
                properties: [
                    "location": JSONSchemaProperty(
                        type: "string",
                        description: "City name"
                    ),
                    "unit": JSONSchemaProperty(
                        type: "string",
                        enum: ["celsius", "fahrenheit"]
                    )
                ],
                required: ["location"]
            )
        )
    )
]

let messages = [
    ChatMessage(role: .user, content: "What's the weather in Paris?")
]

let stream = try await client.chat(
    messages: messages,
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

**CLI Usage:**
```bash
swollama test tools --model llama3.2
```

</details>

<details>
<summary><b>Multimodal (Images)</b></summary>

Process images alongside text for vision-capable models.

```swift
let imageData = try Data(contentsOf: imageURL)
let base64Image = imageData.base64EncodedString()

let messages = [
    ChatMessage(
        role: .user,
        content: "What do you see in this image?",
        images: [base64Image]
    )
]

let stream = try await client.chat(
    messages: messages,
    model: OllamaModelName.parse("llava")!
)

for try await response in stream {
    print(response.message.content)
}
```

**CLI Usage:**
```bash
swollama test images --model llava
```

</details>

<details>
<summary><b>Code Completion with Suffix</b></summary>

Generate code between a prefix and suffix for intelligent code completion.

```swift
let stream = try await client.generateText(
    prompt: "def fibonacci(n):",
    model: OllamaModelName.parse("codellama")!,
    options: GenerationOptions(
        suffix: "\n\n# Example usage\nprint(fibonacci(10))"
    )
)

for try await response in stream {
    print(response.response)
}
```

**CLI Usage:**
```bash
swollama test suffix --model codellama
```

</details>

<details>
<summary><b>Raw Mode (Bypass Templating)</b></summary>

Send prompts directly to the model without applying chat templates.

```swift
let stream = try await client.generateText(
    prompt: "[INST] Why is the sky blue? [/INST]",
    model: OllamaModelName.parse("mistral")!,
    options: GenerationOptions(raw: true)
)
```

</details>

---

## 🔌 API Methods

<details>
<summary><b>Text Generation</b></summary>

Generate text responses with streaming support.

```swift
public func generateText(
    prompt: String,
    model: OllamaModelName,
    options: GenerationOptions = .default
) async throws -> AsyncThrowingStream<GenerateResponse, Error>
```

**Features:**
- Streaming responses
- Context preservation
- Custom generation parameters
- JSON mode support
- Structured outputs

**Example:**
```swift
let stream = try await client.generateText(
    prompt: "Explain quantum computing",
    model: OllamaModelName.parse("llama3.2")!,
    options: GenerationOptions(
        temperature: 0.7,
        topP: 0.9
    )
)

for try await response in stream {
    print(response.response, terminator: "")
    if response.done {
        print("\nDone. Reason: \(response.doneReason ?? "unknown")")
    }
}
```

</details>

<details>
<summary><b>Chat Completions</b></summary>

Multi-turn conversations with message history.

```swift
public func chat(
    messages: [ChatMessage],
    model: OllamaModelName,
    options: ChatOptions = .default
) async throws -> AsyncThrowingStream<ChatResponse, Error>
```

**Features:**
- Multi-turn conversations
- System messages
- Tool/function calling
- Image inputs (multimodal)
- Thinking mode

**Example:**
```swift
var messages = [
    ChatMessage(role: .system, content: "You are a helpful assistant."),
    ChatMessage(role: .user, content: "Hello!")
]

let stream = try await client.chat(
    messages: messages,
    model: OllamaModelName.parse("llama3.2")!
)

var fullResponse = ""
for try await response in stream {
    fullResponse += response.message.content
    if response.done {
        messages.append(ChatMessage(role: .assistant, content: fullResponse))
    }
}
```

</details>

<details>
<summary><b>Embeddings</b></summary>

Generate vector embeddings for text.

```swift
public func generateEmbeddings(
    input: EmbeddingInput,
    model: OllamaModelName,
    options: EmbeddingOptions = .default
) async throws -> EmbeddingResponse
```

**Example:**
```swift
let response = try await client.generateEmbeddings(
    input: .single("Hello world"),
    model: OllamaModelName.parse("nomic-embed-text")!
)

print("Embedding dimensions: \(response.embeddings[0].count)")
```

**CLI Usage:**
```bash
swollama embeddings "Hello world" --model nomic-embed-text
```

</details>

<details>
<summary><b>Model Management</b></summary>

**List Models:**
```swift
let models = try await client.listModels()
for model in models {
    print("\(model.name) - \(model.size) bytes")
}
```

**Show Model Info:**
```swift
let info = try await client.showModel(
    name: OllamaModelName.parse("llama3.2")!,
    verbose: true
)
print("Family: \(info.details.family)")
print("Parameters: \(info.details.parameterSize)")
```

**Pull Model:**
```swift
let progress = try await client.pullModel(
    name: OllamaModelName.parse("llama3.2")!,
    options: PullOptions()
)

for try await update in progress {
    print("Status: \(update.status) - \(update.completed)/\(update.total)")
}
```

**Delete Model:**
```swift
try await client.deleteModel(name: OllamaModelName.parse("old-model")!)
```

**Copy Model:**
```swift
try await client.copyModel(
    source: OllamaModelName.parse("llama3.2")!,
    destination: OllamaModelName.parse("my-llama")!
)
```

**List Running Models:**
```swift
let running = try await client.listRunningModels()
for model in running {
    print("\(model.name) - \(model.sizeVRAM) bytes VRAM")
}
```

</details>

<details>
<summary><b>Model Creation</b></summary>

Create custom models from existing ones or import GGUF/Safetensors files.

```swift
public func createModel(
    _ request: CreateModelRequest
) async throws -> AsyncThrowingStream<OperationProgress, Error>
```

**Create from existing model:**
```swift
let request = CreateModelRequest(
    model: "mario",
    from: "llama3.2",
    system: "You are Mario from Super Mario Bros.",
    parameters: ModelfileParameters(temperature: 0.8)
)

let progress = try await client.createModel(request)
for try await update in progress {
    print(update.status)
}
```

**Quantize a model:**
```swift
let request = CreateModelRequest(
    model: "llama3.2:q4",
    from: "llama3.2:fp16",
    quantize: .q4_K_M
)
```

**CLI Usage:**
```bash
# Create custom model
swollama create mario --from llama3.2 --system "You are Mario"

# Quantize model
swollama create llama3.2:q4 --from llama3.2:fp16 --quantize q4_K_M

# Custom temperature
swollama create assistant --from llama3.2 --temperature 0.7
```

</details>

<details>
<summary><b>Blob Management</b></summary>

Manage large binary files for model creation.

```swift
// Check if blob exists
let exists = try await client.checkBlobExists(
    digest: "sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2"
)

// Push blob
let data = try Data(contentsOf: fileURL)
try await client.pushBlob(
    digest: "sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2",
    data: data
)
```

**CLI Usage:**
```bash
# Check blob
swollama blob check sha256:29fdb92e57cf...

# Push blob
swollama blob push sha256:29fdb92e57cf... model.gguf
```

</details>

<details>
<summary><b>Version Check</b></summary>

Get Ollama server version.

```swift
let version = try await client.getVersion()
print("Ollama version: \(version.version)")
```

**CLI Usage:**
```bash
swollama version
```

</details>

---

## 🚀 Advanced Features

<details>
<summary><b>Custom Generation Parameters</b></summary>

Fine-tune generation behavior with advanced options.

```swift
let options = GenerationOptions(
    temperature: 0.8,
    topK: 40,
    topP: 0.9,
    repeatPenalty: 1.1,
    seed: 42,
    numPredict: 100,
    stop: ["</s>", "\n\n"]
)

let stream = try await client.generateText(
    prompt: "Write a story",
    model: model,
    options: options
)
```

**Available parameters:**
- `temperature`: Creativity level (0.0 - 2.0)
- `topK`: Token sampling limit
- `topP`: Nucleus sampling threshold
- `topA`: Alternative sampling method
- `minP`: Minimum probability threshold
- `repeatPenalty`: Penalize repetition
- `presencePenalty`: Penalize token presence
- `frequencyPenalty`: Penalize token frequency
- `mirostat`: Mirostat sampling mode
- `seed`: Deterministic generation
- `numPredict`: Max tokens to generate
- `stop`: Stop sequences

</details>

<details>
<summary><b>Context Preservation</b></summary>

Preserve context across generation calls for continuation.

```swift
let stream = try await client.generateText(
    prompt: "Once upon a time",
    model: model
)

var context: [Int]?
for try await response in stream {
    if response.done {
        context = response.context
    }
}

// Continue with preserved context
let continuation = try await client.generateText(
    prompt: "The story continues",
    model: model,
    options: GenerationOptions(context: context)
)
```

</details>

<details>
<summary><b>Keep-Alive Configuration</b></summary>

Control how long models stay loaded in memory.

```swift
let client = OllamaClient(
    configuration: OllamaConfiguration(
        defaultKeepAlive: 300  // 5 minutes
    )
)

// Per-request keep-alive
let options = GenerationOptions(keepAlive: 600)  // 10 minutes
```

</details>

<details>
<summary><b>Error Handling</b></summary>

Comprehensive error handling with typed errors.

```swift
do {
    let stream = try await client.generateText(prompt: "Hello", model: model)
    for try await response in stream {
        print(response.response)
    }
} catch OllamaError.modelNotFound {
    print("Model not found")
} catch OllamaError.serverError(let message) {
    print("Server error: \(message)")
} catch OllamaError.networkError(let error) {
    print("Network error: \(error)")
} catch OllamaError.decodingError(let error) {
    print("Failed to decode: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

**Error types:**
- `invalidResponse`: Invalid server response
- `decodingError`: JSON decoding failed
- `serverError`: Server returned error (5xx)
- `modelNotFound`: Model doesn't exist (404)
- `cancelled`: Request cancelled
- `networkError`: Network failure
- `unexpectedStatusCode`: Unexpected HTTP status
- `invalidParameters`: Invalid request parameters
- `fileError`: File operation failed

</details>

---

## 🖥️ CLI Commands

<details>
<summary><b>Complete Command Reference</b></summary>

```bash
# Model Management
swollama list                          # List available models
swollama show <model>                  # Show model information
swollama show <model> --verbose        # Show detailed model info
swollama pull <model>                  # Download a model
swollama push <model>                  # Upload a model to registry
swollama copy <source> <dest>          # Copy a model
swollama delete <model>                # Delete a model
swollama ps                            # List running models

# Model Creation
swollama create <name> --from <model> --system "prompt"
swollama create <name> --from <model> --quantize q4_K_M
swollama create <name> --from <model> --temperature 0.7

# Generation
swollama generate <model>              # Interactive text generation
swollama chat <model>                  # Interactive chat session
swollama embeddings <text>             # Generate embeddings

# Testing & Features
swollama test                          # Run all feature tests
swollama test structured               # Test JSON Schema outputs
swollama test thinking                 # Test reasoning models
swollama test tools                    # Test function calling
swollama test images                   # Test image inputs
swollama test suffix                   # Test code completion
swollama test json                     # Test JSON mode

# Utilities
swollama version                       # Server version
swollama blob check <digest>           # Check if blob exists
swollama blob push <digest> <file>     # Upload blob

# Options
--host <url>                           # Custom Ollama server URL
--help, -h                             # Show help
--version, -v                          # Show CLI version
```

</details>

<details>
<summary><b>Interactive Chat</b></summary>

Start an interactive chat session with various commands.

```bash
swollama chat llama3.2
```

**In-chat commands:**
- `/exit`, `/quit` - End conversation
- `/clear` - Clear conversation history
- `/save [filename]` - Save conversation to file
- `/load [filename]` - Load conversation from file
- `/system <message>` - Set system message
- `/model <name>` - Switch model
- `/retry` - Retry last message
- `/undo` - Remove last exchange
- `/tokens` - Toggle token count display
- `/help` - Show available commands

</details>

---

## 🌐 Platform Support

<details>
<summary><b>Supported Platforms</b></summary>

- ✅ **macOS 14+** - Full native support with URLSession
- ✅ **Linux** - Optimized with curl subprocess for streaming
- ✅ **iOS 17+** - Full support for mobile apps
- ✅ **Docker** - Container-ready deployment

**Platform-specific optimizations:**
- macOS/iOS: Native `URLSession.bytes(for:)` streaming
- Linux: `curl` subprocess for efficient HTTP streaming
- All platforms: Actor-based thread safety
- Zero external dependencies

</details>

<details>
<summary><b>Performance Features</b></summary>

- **Zero dependencies**: Pure Swift + Foundation
- **Efficient streaming**: 64KB buffer size
- **Connection pooling**: Automatic connection reuse
- **Retry logic**: Exponential backoff for transient failures
- **Resource limits**: Configurable timeouts and retries
- **Linux optimizations**: Custom compiler flags for performance

</details>

---

## 📚 API Endpoint Coverage

All Ollama API endpoints are fully supported:

| Endpoint | Method | Description | Status |
|----------|--------|-------------|--------|
| `/api/generate` | POST | Text generation | ✅ |
| `/api/chat` | POST | Chat completions | ✅ |
| `/api/embed` | POST | Generate embeddings | ✅ |
| `/api/create` | POST | Create model | ✅ |
| `/api/tags` | GET | List models | ✅ |
| `/api/show` | POST | Show model info | ✅ |
| `/api/copy` | POST | Copy model | ✅ |
| `/api/delete` | DELETE | Delete model | ✅ |
| `/api/pull` | POST | Pull model | ✅ |
| `/api/push` | POST | Push model | ✅ |
| `/api/ps` | GET | Running models | ✅ |
| `/api/blobs/:digest` | HEAD | Check blob | ✅ |
| `/api/blobs/:digest` | POST | Push blob | ✅ |
| `/api/version` | GET | Server version | ✅ |

---

## 🔗 Additional Resources

- **Official API Documentation**: https://github.com/ollama/ollama/blob/main/docs/api.md
- **Package Documentation**: https://guitaripod.github.io/Swollama/documentation/swollama/
- **GitHub Repository**: https://github.com/guitaripod/Swollama
- **Swift Package Index**: https://swiftpackageindex.com/guitaripod/Swollama

---

## 📝 Notes

- All code examples use the latest API with proper error handling
- The `done_reason` field is available in both `ChatResponse` and `GenerateResponse`
- Models are parsed using `OllamaModelName.parse()` which supports `[namespace/]name[:tag]` format
- Thread safety is guaranteed through Swift actors
- All streaming operations return `AsyncThrowingStream<T, Error>`
