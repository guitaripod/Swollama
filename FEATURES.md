# Swollama Feature Documentation

This document covers all features implemented in Swollama, including the latest Ollama API capabilities.

## Table of Contents

1. [New Features](#new-features)
2. [Structured Outputs](#structured-outputs)
3. [Thinking Models](#thinking-models)
4. [Model Creation](#model-creation)
5. [Blob Management](#blob-management)
6. [Advanced Generation Options](#advanced-generation-options)
7. [CLI Commands](#cli-commands)

## New Features

Swollama now supports ALL features from the Ollama API, including:

- ✅ **Structured Outputs** with JSON Schema
- ✅ **Thinking Models** (deepseek-r1 support)
- ✅ **Model Creation** from GGUF/Safetensors
- ✅ **Blob Management** for large files
- ✅ **Version Endpoint**
- ✅ **Enhanced Show Model** with verbose option
- ✅ **Raw Mode** for direct prompting
- ✅ **Suffix Parameter** for code completion
- ✅ **Tool/Function Calling**
- ✅ **Multimodal Support** (images)

## Structured Outputs

Generate responses that conform to a specific JSON schema:

```swift
import Swollama

let client = OllamaClient()

// Define the schema
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

// Generate with structured output
let request = GenerateRequest(
    model: "llama3.2",
    prompt: "Tell me about a software developer named Alex",
    format: .jsonSchema(schema)
)

let stream = try await client.generateText(
    prompt: request.prompt,
    model: OllamaModelName.parse("llama3.2")!,
    options: GenerationOptions(format: request.format)
)

// The response will be valid JSON matching the schema
```

### CLI Usage

```bash
# Test structured outputs
swollama test structured --model llama3.1

# The test command demonstrates structured output generation
```

## Thinking Models

Support for models that show their reasoning process:

```swift
// Enable thinking mode
let request = ChatRequest(
    model: "deepseek-r1",
    messages: [
        ChatMessage(role: .user, content: "Solve this step by step: 2+2")
    ],
    think: true  // Enable thinking
)

let response = try await client.chat(
    messages: request.messages,
    model: OllamaModelName.parse("deepseek-r1")!,
    options: ChatOptions(think: true)
)

// Access the thinking process
if let thinking = response.message.thinking {
    print("Model's thinking: \(thinking)")
}
print("Final answer: \(response.message.content)")
```

### CLI Usage

```bash
# Test thinking models
swollama test thinking --model deepseek-r1
```

## Model Creation

Create custom models from existing ones or import GGUF/Safetensors:

```swift
// Create from existing model
let request = CreateModelRequest(
    model: "mario",
    from: "llama3.2",
    system: "You are Mario from Super Mario Bros.",
    parameters: ModelfileParameters(temperature: 0.8)
)

let progress = try await client.createModel(request)

// Create from GGUF file
let ggufRequest = CreateModelRequest(
    model: "my-model",
    files: ["model.gguf": "sha256:432f310a77f..."]
)

// Quantize a model
let quantizeRequest = CreateModelRequest(
    model: "llama3.2:quantized",
    from: "llama3.2:fp16",
    quantize: .q4_K_M
)
```

### CLI Usage

```bash
# Create a custom model
swollama create mario --from llama3.2 --system "You are Mario"

# Quantize a model
swollama create llama3.2:q4 --from llama3.2:fp16 --quantize q4_K_M

# Create with custom temperature
swollama create assistant --from llama3.2 --temperature 0.7
```

## Blob Management

Manage large files for model creation:

```swift
// Check if a blob exists
let exists = try await client.checkBlobExists(
    digest: "sha256:29fdb92e57cf..."
)

// Push a blob
let modelData = try Data(contentsOf: modelURL)
try await client.pushBlob(
    digest: "sha256:29fdb92e57cf...",
    data: modelData
)
```

### CLI Usage

```bash
# Check if a blob exists
swollama blob check sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2

# Push a blob
swollama blob push sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2 model.gguf
```

## Advanced Generation Options

### Suffix Parameter (Code Completion)

```swift
let request = GenerateRequest(
    model: "codellama",
    prompt: "def fibonacci(n):",
    suffix: "\n\n# Example usage\nprint(fibonacci(10))"
)
```

### Raw Mode

```swift
let request = GenerateRequest(
    model: "mistral",
    prompt: "[INST] Why is the sky blue? [/INST]",
    raw: true  // Bypass templating
)
```

### JSON Mode

```swift
let request = GenerateRequest(
    model: "llama3.2",
    prompt: "List colors as JSON",
    format: .json  // Basic JSON formatting
)
```

## CLI Commands

### Complete Command Reference

```bash
# Model Management
swollama list                          # List available models
swollama show llama3.2                 # Show model info
swollama show llama3.2 --verbose       # Show verbose model info
swollama pull llama3.2                 # Download a model
swollama push myuser/model:latest     # Upload a model
swollama copy llama3.2 mycopy         # Copy a model
swollama delete oldmodel               # Delete a model
swollama ps                            # List running models

# Model Creation
swollama create mymodel --from llama3.2 --system "Custom prompt"
swollama create mymodel --from llama3.2 --quantize q4_K_M

# Generation
swollama generate llama3.2             # Generate text
swollama chat llama3.2                 # Interactive chat
swollama embeddings "Hello world"      # Generate embeddings

# Testing & Utilities
swollama test                          # Run all feature tests
swollama test structured               # Test structured outputs
swollama test thinking                 # Test thinking models
swollama version                       # Show server version

# Blob Management
swollama blob check sha256:...         # Check blob exists
swollama blob push sha256:... file    # Push blob
```

### Test Command

The `test` command demonstrates all new features:

```bash
# Run all tests
swollama test

# Test specific features
swollama test structured    # JSON Schema outputs
swollama test thinking      # Thinking models
swollama test json          # JSON mode
swollama test images        # Multimodal
swollama test tools         # Function calling
swollama test suffix        # Code completion
```

## API Compatibility

Swollama implements the complete Ollama API as documented at:
https://github.com/ollama/ollama/blob/main/docs/api.md

All endpoints are supported:
- `/api/generate` - Text generation
- `/api/chat` - Chat completions
- `/api/embed` - Embeddings (new endpoint)
- `/api/embeddings` - Legacy embeddings
- `/api/create` - Model creation
- `/api/tags` - List models
- `/api/show` - Show model info
- `/api/copy` - Copy model
- `/api/delete` - Delete model
- `/api/pull` - Pull model
- `/api/push` - Push model
- `/api/ps` - List running models
- `/api/blobs/:digest` - Blob management
- `/api/version` - Server version

## Swift Package Usage

```swift
import Swollama

// Initialize client
let client = OllamaClient(baseURL: URL(string: "http://localhost:11434")!)

// Use structured outputs
let schema = JSONSchema(type: "object", properties: [...])
let response = try await client.generateText(
    prompt: "Generate data",
    model: model,
    options: GenerationOptions(format: .jsonSchema(schema))
)

// Use thinking models
let chatResponse = try await client.chat(
    messages: messages,
    model: model,
    options: ChatOptions(think: true)
)

// Create models
let progress = try await client.createModel(
    CreateModelRequest(model: "custom", from: "llama3.2")
)
```

## Platform Support

- ✅ macOS 14+
- ✅ iOS 17+
- ✅ Linux (Ubuntu, Arch, Debian, etc.)
- ✅ Docker

## Performance

- Zero dependencies
- Optimized for Linux with specific compiler flags
- Efficient streaming with buffered I/O
- Connection pooling
- Automatic retry with exponential backoff