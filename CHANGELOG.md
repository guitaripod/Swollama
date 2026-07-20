# Changelog

All notable changes to Swollama are documented here. This project adheres to
[Semantic Versioning](https://semver.org/).

## 4.2.0

A correctness, consumability, and Swift 6 readiness release. The public API is source-compatible
with 4.1.0 (additive only). Validated end-to-end on Linux (curl streaming path) and macOS (native
`URLSession` streaming path).

### Fixed — streaming

- **Linux: the final response chunk could be dropped.** The curl drain loop read
  `FileHandle.availableData` twice per iteration (a consuming read), discarding bytes — including the
  terminal `done: true` line and last token. It now reads once per iteration.
- **Linux: a fabricated `200` masked real errors.** When curl's response headers were slow to arrive
  the client synthesized an `HTTP 200`, hiding genuine 4xx/5xx failures behind a later decode error.
  The real parsed status now drives error handling.
- **Linux: streaming was capped at 300s total.** `curl --max-time 300` killed any generation, pull,
  or push exceeding five minutes. Replaced with a connection timeout; long operations run to
  completion.
- **Linux: request headers (including auth) were dropped**, and `stderr` was merged into the response
  body. Custom headers now pass through and `stderr` is captured separately for diagnostics.
- **macOS/iOS: streaming buffered up to 64KB before yielding**, so token-by-token output arrived in
  large batches. Chunks now flush on each newline.
- **macOS/iOS: cancelling a stream leaked the underlying request.** The `URLSession` bytes task is now
  torn down on termination, matching the Linux path.
- **macOS/iOS: a 30s request timeout aborted cold model loads.** Streaming now uses a separate,
  generous idle timeout (``OllamaConfiguration/streamTimeoutInterval``).

### Fixed — errors

- Ollama's `{"error": "..."}` response bodies are now parsed and surfaced instead of dumping the raw
  string (or a bare status code) into the error.
- A mid-stream `{"error": ...}` line is now reported as ``OllamaError/serverError(_:)`` instead of a
  confusing ``OllamaError/decodingError(_:)``.

### Added

- **Authentication:** ``OllamaConfiguration/apiKey`` sends an `Authorization: Bearer` header on every
  request (native and streaming), enabling authenticated and cloud hosts.
- **Resilience:** HTTP 429 is retried honoring `Retry-After`; retries use exponential backoff with
  jitter. New ``OllamaError`` cases: `authenticationFailed`, `rateLimited`.
- **Insecure TLS:** ``OllamaConfiguration/allowsInsecureConnections`` is now wired up (curl `-k` on
  Linux; a trust-accepting session delegate on Apple platforms) — previously it was dead config.
- **API design:** `generateText`, `chat`, `generateEmbeddings`, and `generateEmbedding` are now part
  of ``OllamaProtocol``. New non-streaming conveniences `completeText(...)` and `completeChat(...)`,
  and a generic `AsyncSequence.collect()`.
- **Swift 6 readiness:** the public value types are now `Sendable` and the library builds clean under
  `-strict-concurrency=complete`. ``OllamaModelName`` gains `Hashable`, `Equatable`, and
  `CustomStringConvertible`.
- **Platforms:** package now also declares tvOS 17, watchOS 10, and visionOS 1.
- **CLI:** one-shot chat (`swollama chat <model> "prompt"` or piped stdin); `OLLAMA_HOST` and
  `OLLAMA_API_KEY` environment variables; status messages routed to stderr so stdout stays pipeable;
  ANSI colors gated on a TTY and `NO_COLOR`; unknown `chat` flags now error instead of being ignored.

### Changed

- **`Package.swift` no longer applies `.unsafeFlags` to the library target.** Unsafe build flags
  prevented Swollama from being used as a versioned (`from:`) dependency at all. Release
  optimizations remain in the Dockerfile / release build invocation.
- **HTTP 429 is now retryable.** Previously it surfaced immediately as
  `unexpectedStatusCode(429)`; it is now `rateLimited` and retried.

### Removed

- Dead public enums `ModelFamily`, `ModelFormat`, and `QuantizationLevel` (unused).

### Infrastructure

- Added a CI workflow (`ci.yml`) that builds, runs the full test suite, enforces formatting, and gates
  the library on `-strict-concurrency=complete` — all on the free `ubuntu-latest` runner.

## 4.1.0

CLI now exercises the full 4.0.0 library surface (dogfooding) and gains useful flags.
The library API is unchanged from 4.0.0.

### Added

- `swollama chat <model> --think[-level <lvl>]` streams the model's reasoning;
  `--format json` for structured output; `--keep-alive <seconds>`.
- `swollama show <model> --verbose` prints the full `model_info` and tensor listing;
  the summary view now shows license, system, renderer, parser, requires, remote
  model/host, and context/embedding lengths.
- `swollama ps` shows the loaded runtime context length and remote model/host.
- `swollama embeddings --legacy` exercises the legacy `/api/embeddings` endpoint.

### Fixed

- `swollama --version` reported a stale `v1.0.0`.
- Removed a dead, unused `ChatCommand` (its shared `TerminalStyle` moved to its own file).
- DocC now builds on a free Linux runner (`swift-docc-plugin`) instead of a macOS
  runner; the plugin is gated behind `SWOLLAMA_DOCS` so consumers keep zero
  dependencies. Cleaned up all DocC symbol-link warnings.

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
