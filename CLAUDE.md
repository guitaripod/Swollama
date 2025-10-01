# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Bash Commands

```bash
swift build                           # Build the project
swift build -c release                # Build release
swift test                            # Run tests
swift test --filter SwollamaTests     # Run specific test suite
swift run SwollamaCLI <command>       # Run CLI
```

## Architecture

**Library**: Protocol-oriented Swift client for Ollama API
- `OllamaClient` is an **actor** (thread-safe, use `await` for all methods)
- `OllamaProtocol` defines all API operations
- All streaming operations return `AsyncThrowingStream<T, Error>`

**CLI**: Command pattern in `Sources/SwollamaCLI/Commands/`
- Each command implements `CommandProtocol`
- Entry point: `SwollamaCLI.swift`

## Critical Platform Details

**Linux Streaming**: IMPORTANT - Linux uses curl subprocess for HTTP streaming because Foundation on Linux lacks proper streaming support
- See `NetworkingSupport+Streaming.swift:19-163` for implementation
- Uses `#if canImport(FoundationNetworking)` for conditional compilation
- Linux requires `import FoundationNetworking` for URLSession

**macOS/iOS**: Uses native `URLSession.bytes(for:)` API

## Model Name Parsing

IMPORTANT: `OllamaModelName.parse(_:)` returns optional - always guard:
```swift
guard let model = OllamaModelName.parse("llama3.2") else {
    throw CLIError.invalidArgument("Invalid model name format")
}
```
Format: `[namespace/]name[:tag]` (tag defaults to "latest")

## Code Patterns

**Streaming responses**:
```swift
for try await response in try await client.chat(messages: messages, model: model) {
    print(response.message.content, terminator: "")
}
```

**Error types**: Use `OllamaError` for library, `CLIError` for CLI

**Code style**: Never add code comments

**Formatting**: Run `swift-format format --in-place --recursive Sources/ Tests/` before committing

**Tools**: Use the latest tools available

## Testing

Tests in `Tests/SwollamaTests/` - add tests when implementing features
