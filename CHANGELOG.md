# Changelog

All notable changes to Swollama are documented here. This project adheres to
[Semantic Versioning](https://semver.org/).

## 4.0.0

Comprehensive update bringing Swollama in line with the current Ollama REST API
(verified against Ollama server `0.32.x`). Validated end-to-end on Linux (curl
streaming path) and macOS (native `URLSession` streaming path).

### Breaking changes

- **`think` is now `ThinkingMode?`** instead of `Bool?` on `ChatOptions`,
  `GenerationOptions`, `ChatRequest`, and `GenerateRequest`. Boolean literals still
  work (`think: true`); to pass a `Bool` *value*, wrap it: `ThinkingMode(myBool)`.
  `ThinkingMode` also supports reasoning-effort levels: `.low`, `.medium`, `.high`,
  `.max`, or `.level("…")`.
- **`ModelInformation.modelfile`, `.template`, and `.parameters` are now optional**
  (`String?`). Some models (embedding models, remote/cloud stubs) legitimately omit
  them; decoding these previously threw.
- **`ResponseFormat` gained a `.schema(JSONValue)` case** for arbitrary JSON Schemas.
  Exhaustive `switch` statements over `ResponseFormat` must handle the new case.

### Added

- **Thinking / reasoning:** reasoning-effort levels; `GenerateResponse.thinking`
  (Ollama returns generate thinking at the top level, chat under `message.thinking`).
- **Structured outputs:** `ResponseFormat.schema(JSONValue)` for schemas beyond the
  typed `JSONSchema` builder (`$defs`, `anyOf`, nested definitions, …).
- **Tool calling:** `ToolCall.id`, `FunctionCall.index`, `ChatMessage.toolName`
  (`tool_name`) and `ChatMessage.toolCallId` (`tool_call_id`).
- **Model introspection (`/api/show`):** `license`, `modelInfo`, `tensors`,
  `capabilities`, `requires`, `modifiedAt`, `system`, `renderer`, `parser`,
  `projectorInfo`, plus remote-model fields.
- **`/api/tags` & `/api/ps`:** per-model `capabilities`,
  `ModelDetails.contextLength`/`.embeddingLength`, runtime `contextLength`,
  and remote-model fields.
- **Embeddings:** `dimensions` (Matryoshka truncation) on `/api/embed`, and the
  legacy `/api/embeddings` endpoint via `generateEmbedding(prompt:model:options:)`.
- **Generation:** `logprobs`/`topLogprobs`, `truncate`/`shift`, image-generation
  fields (`width`/`height`/`steps` and `image`/`completed`/`total`),
  `remoteModel`/`remoteHost`, and `ModelOptions.draftNumPredict`.
- New public types: `JSONValue`, `ThinkingMode`, `Logprob`/`TopLogprob`,
  `ModelCapability`, `ModelTensor`, `LegacyEmbeddingResponse`.
- **CLI:** `swollama show` and `swollama list` now display capabilities (and more);
  `swollama embeddings --dimensions`; `swollama generate --prompt/--system/--think`
  for non-interactive, scriptable one-shot generation (response on stdout, thinking
  on stderr); interactive chat now streams a model's thinking.

### Fixed

- Robust RFC 3339 timestamp parsing (nanosecond precision + numeric offsets), fixing
  a latent `/api/ps` decode failure whenever a model was loaded.
- `checkBlobExists` now correctly returns `false` for a missing blob instead of
  throwing `modelNotFound`.
- `JSONValue.intValue` no longer traps on out-of-range whole doubles.
- `ModelDetails` decodes leniently, tolerating models that omit `parameter_size`
  or `quantization_level`.
- Corrected non-compiling README examples and added a compile-time guard for them.
