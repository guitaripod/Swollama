import XCTest

@testable import Swollama

/// Coverage for API fields and types added to track the current Ollama server API.
/// Decoding fixtures mirror real `0.3x` server responses.
final class APICoverageTests: XCTestCase {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// A decoder configured like ``OllamaClient``'s, for types that rely on its date strategy.
    private var ollamaDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = OllamaDate.parse(string) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "bad date")
                )
            }
            return date
        }
        return decoder
    }

    // MARK: - ThinkingMode

    func testThinkingModeEncoding() throws {
        XCTAssertEqual(
            String(data: try encoder.encode(ThinkingMode.enabled), encoding: .utf8),
            "true"
        )
        XCTAssertEqual(
            String(data: try encoder.encode(ThinkingMode.disabled), encoding: .utf8),
            "false"
        )
        XCTAssertEqual(
            String(data: try encoder.encode(ThinkingMode.high), encoding: .utf8),
            "\"high\""
        )
        XCTAssertEqual(
            String(data: try encoder.encode(ThinkingMode.max), encoding: .utf8),
            "\"max\""
        )
        XCTAssertEqual(
            String(data: try encoder.encode(ThinkingMode.level("custom")), encoding: .utf8),
            "\"custom\""
        )
    }

    func testThinkingModeDecoding() throws {
        XCTAssertEqual(try decoder.decode(ThinkingMode.self, from: Data("true".utf8)), .enabled)
        XCTAssertEqual(try decoder.decode(ThinkingMode.self, from: Data("false".utf8)), .disabled)
        XCTAssertEqual(
            try decoder.decode(ThinkingMode.self, from: Data("\"low\"".utf8)),
            .level("low")
        )
    }

    func testThinkingModeLiteralAndBoolInit() {
        let enabled: ThinkingMode = true
        XCTAssertEqual(enabled, .enabled)
        XCTAssertEqual(ThinkingMode(false), .disabled)
    }

    func testThinkingModeInRequestEncodesInline() throws {
        let request = ChatRequest(
            model: "m",
            messages: [ChatMessage(role: .user, content: "hi")],
            think: .high
        )
        let json = String(data: try encoder.encode(request), encoding: .utf8)!
        XCTAssertTrue(json.contains("\"think\":\"high\""), json)
    }

    // MARK: - JSONValue

    func testJSONValueRoundTrip() throws {
        let json = Data(
            #"{"i":1,"d":1.5,"s":"x","b":true,"n":null,"arr":[1,2],"obj":{"k":"v"}}"#.utf8
        )
        let value = try decoder.decode(JSONValue.self, from: json)
        XCTAssertEqual(value["i"]?.intValue, 1)
        XCTAssertEqual(value["d"]?.doubleValue, 1.5)
        XCTAssertEqual(value["s"]?.stringValue, "x")
        XCTAssertEqual(value["b"]?.boolValue, true)
        XCTAssertEqual(value["n"], JSONValue.null)
        XCTAssertEqual(value["arr"]?.arrayValue?.count, 2)
        XCTAssertEqual(value["obj"]?["k"]?.stringValue, "v")

        let reencoded = try decoder.decode(JSONValue.self, from: try encoder.encode(value))
        XCTAssertEqual(reencoded, value)
    }

    func testJSONValueLiterals() {
        let value: JSONValue = ["name": "Alex", "age": 28, "active": true, "tags": ["a", "b"]]
        XCTAssertEqual(value["age"]?.intValue, 28)
        XCTAssertEqual(value["tags"]?.arrayValue?.count, 2)
    }

    func testJSONValueIntValueEdgeCases() {
        XCTAssertEqual(JSONValue.double(42.0).intValue, 42)
        XCTAssertNil(JSONValue.double(1.5).intValue)
        // Whole but far out of Int range: must return nil, not trap.
        XCTAssertNil(JSONValue.double(1e300).intValue)
        XCTAssertEqual(JSONValue.double(3.0).doubleValue, 3.0)
    }

    // MARK: - OllamaDate

    func testOllamaDateParsesNanosecondsAndOffset() throws {
        let date = try XCTUnwrap(OllamaDate.parse("2026-04-11T13:53:18.632244808+03:00"))
        // 13:53:18+03:00 == 10:53:18Z; build the oracle independently via DateComponents.
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 11
        components.hour = 10
        components.minute = 53
        components.second = 18
        components.timeZone = TimeZone(identifier: "UTC")
        let expected = try XCTUnwrap(Calendar(identifier: .gregorian).date(from: components))
        XCTAssertEqual(date.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1.0)
    }

    func testOllamaDateParsesZuluAndMillis() {
        XCTAssertNotNil(OllamaDate.parse("2026-07-19T12:00:00.123Z"))
        XCTAssertNotNil(OllamaDate.parse("2026-07-19T12:00:00Z"))
        XCTAssertNil(OllamaDate.parse("not-a-date"))
    }

    // MARK: - /api/show

    func testShowResponseDecoding() throws {
        let json = Data(
            #"""
            {
              "license": "Apache 2.0",
              "modelfile": "FROM foo",
              "parameters": "temperature 1",
              "template": "{{ .Prompt }}",
              "system": "You are helpful",
              "renderer": "harmony",
              "parser": "harmony",
              "details": {
                "parent_model": "",
                "format": "gguf",
                "family": "qwen3",
                "families": ["qwen3"],
                "parameter_size": "0.6B",
                "quantization_level": "Q4_K_M",
                "context_length": 40960,
                "embedding_length": 1024
              },
              "model_info": {
                "general.architecture": "qwen3",
                "general.parameter_count": 751632384,
                "qwen3.attention.head_count": 16,
                "qwen3.rope.freq_base": 1000000.0,
                "tokenizer.ggml.add_bos_token": false
              },
              "tensors": [
                {"name": "blk.0.attn_q.weight", "type": "Q4_K", "shape": [1024, 2048]}
              ],
              "capabilities": ["completion", "tools", "thinking", "insert"],
              "modified_at": "2026-07-04T00:28:51.693665967+03:00",
              "requires": "0.20.0"
            }
            """#.utf8
        )
        let info = try decoder.decode(ModelInformation.self, from: json)
        XCTAssertEqual(info.license, "Apache 2.0")
        XCTAssertEqual(info.system, "You are helpful")
        XCTAssertEqual(info.renderer, "harmony")
        XCTAssertEqual(info.parser, "harmony")
        XCTAssertEqual(info.details.contextLength, 40960)
        XCTAssertEqual(info.details.embeddingLength, 1024)
        XCTAssertEqual(info.modelInfo?["general.architecture"]?.stringValue, "qwen3")
        XCTAssertEqual(info.modelInfo?["general.parameter_count"]?.intValue, 751_632_384)
        XCTAssertEqual(info.modelInfo?["qwen3.rope.freq_base"]?.doubleValue, 1_000_000.0)
        XCTAssertEqual(info.modelInfo?["tokenizer.ggml.add_bos_token"]?.boolValue, false)
        XCTAssertEqual(info.tensors?.first?.shape, [1024, 2048])
        XCTAssertEqual(info.capabilities, [.completion, .tools, .thinking, .insert])
        XCTAssertEqual(info.requires, "0.20.0")
        XCTAssertNotNil(info.modifiedAt)
    }

    func testShowResponseMinimal() throws {
        // Embedding-style model: no modelfile/template/parameters, sparse details.
        let json = Data(
            #"{"details":{"format":"gguf","family":"bert"},"model_info":{},"capabilities":["embedding"]}"#
                .utf8
        )
        let info = try decoder.decode(ModelInformation.self, from: json)
        XCTAssertNil(info.modelfile)
        XCTAssertNil(info.template)
        XCTAssertEqual(info.details.family, "bert")
        XCTAssertEqual(info.details.parameterSize, "")
        XCTAssertEqual(info.capabilities, [.embedding])
    }

    // MARK: - /api/tags

    func testTagsDecodingWithCapabilities() throws {
        let json = Data(
            #"""
            {"models":[{
              "name":"qwen3:0.6b","model":"qwen3:0.6b",
              "modified_at":"2026-07-04T00:28:51.693665967+03:00",
              "size":500000000,"digest":"abc123",
              "details":{"parent_model":"","format":"gguf","family":"qwen3","families":["qwen3"],"parameter_size":"0.6B","quantization_level":"Q4_K_M","context_length":40960,"embedding_length":1024},
              "capabilities":["completion","tools","thinking"]
            }]}
            """#.utf8
        )
        let response = try decoder.decode(ModelsResponse.self, from: json)
        let model = try XCTUnwrap(response.models.first)
        XCTAssertEqual(model.capabilities, [.completion, .tools, .thinking])
        XCTAssertEqual(model.details.contextLength, 40960)
    }

    // MARK: - /api/generate response

    func testGenerateResponseThinkingAndToolCalls() throws {
        let json = Data(
            #"""
            {
              "model":"qwen3:0.6b","created_at":"2026-07-19T12:00:00.123456789Z",
              "response":"final","thinking":"let me think","done":true,"done_reason":"stop",
              "tool_calls":[{"id":"call_1","function":{"index":0,"name":"get_weather","arguments":{"city":"Paris"}}}],
              "eval_count":10
            }
            """#.utf8
        )
        let response = try decoder.decode(GenerateResponse.self, from: json)
        XCTAssertEqual(response.thinking, "let me think")
        XCTAssertEqual(response.toolCalls?.first?.id, "call_1")
        XCTAssertEqual(response.toolCalls?.first?.function.index, 0)
        XCTAssertEqual(response.toolCalls?.first?.function.name, "get_weather")
        XCTAssertTrue(response.toolCalls!.first!.function.arguments.contains("Paris"))
    }

    // MARK: - Chat message tool fields

    func testChatMessageToolFieldsDecoding() throws {
        let json = Data(
            #"""
            {"role":"assistant","content":"",
             "tool_calls":[{"id":"call_9","function":{"index":2,"name":"lookup","arguments":{"q":"x"}}}]}
            """#.utf8
        )
        let message = try decoder.decode(ChatMessage.self, from: json)
        XCTAssertEqual(message.toolCalls?.first?.id, "call_9")
        XCTAssertEqual(message.toolCalls?.first?.function.index, 2)

        let toolResult = ChatMessage(
            role: .tool,
            content: "sunny",
            toolName: "get_weather",
            toolCallId: "call_9"
        )
        let encoded = String(data: try encoder.encode(toolResult), encoding: .utf8)!
        XCTAssertTrue(encoded.contains("\"tool_name\":\"get_weather\""), encoded)
        XCTAssertTrue(encoded.contains("\"tool_call_id\":\"call_9\""), encoded)
    }

    // MARK: - /api/ps

    func testRunningModelDecoding() throws {
        let json = Data(
            #"""
            {"models":[{
              "name":"qwen3:0.6b","model":"qwen3:0.6b","size":600000000,"digest":"abc",
              "details":{"parent_model":"","format":"gguf","family":"qwen3","families":["qwen3"],"parameter_size":"0.6B","quantization_level":"Q4_K_M"},
              "expires_at":"2026-07-19T12:05:00.632244808+03:00","size_vram":600000000,"context_length":4096
            }]}
            """#.utf8
        )
        let response = try ollamaDecoder.decode(RunningModelsResponse.self, from: json)
        let model = try XCTUnwrap(response.models.first)
        XCTAssertEqual(model.sizeVRAM, 600_000_000)
        XCTAssertEqual(model.contextLength, 4096)
    }

    // MARK: - Structured output

    func testResponseFormatArbitrarySchema() throws {
        let schema: JSONValue = [
            "type": "object",
            "properties": ["answer": ["type": "string"]],
            "required": ["answer"],
        ]
        let format = ResponseFormat.schema(schema)
        let roundTrip = try decoder.decode(JSONValue.self, from: try encoder.encode(format))
        XCTAssertEqual(roundTrip["type"]?.stringValue, "object")
        XCTAssertEqual(roundTrip["required"]?.arrayValue?.first?.stringValue, "answer")
    }

    // MARK: - Embeddings

    func testEmbeddingRequestDimensions() throws {
        let request = EmbeddingRequest(
            model: "embeddinggemma",
            input: .single("hello"),
            truncate: true,
            dimensions: 256
        )
        let json = String(data: try encoder.encode(request), encoding: .utf8)!
        XCTAssertTrue(json.contains("\"dimensions\":256"), json)
    }

    func testLegacyEmbeddingResponse() throws {
        let json = Data(#"{"embedding":[0.1,0.2,0.3]}"#.utf8)
        let response = try decoder.decode(LegacyEmbeddingResponse.self, from: json)
        XCTAssertEqual(response.embedding, [0.1, 0.2, 0.3])
    }

    // MARK: - Model capability extensibility

    func testUnknownCapabilityDecodes() throws {
        let caps = try decoder.decode(
            [ModelCapability].self,
            from: Data(#"["vision","future_cap"]"#.utf8)
        )
        XCTAssertEqual(caps, [.vision, ModelCapability(rawValue: "future_cap")])
    }

    /// Compile-only guard: the option/tool/schema construction shown in README examples must stay valid.
    /// Never invoked (no network) — its purpose is to fail the build if the public API drifts.
    @available(*, unavailable)
    func _readmeExamplesCompileCheck(_ client: OllamaClient, _ model: OllamaModelName) async throws
    {
        _ = try await client.generateText(
            prompt: "x",
            model: model,
            options: GenerationOptions(
                modelOptions: ModelOptions(numPredict: 200, topP: 0.9, temperature: 0.7)
            )
        )

        _ = try await client.chat(
            messages: [ChatMessage(role: .user, content: "x")],
            model: model,
            options: ChatOptions(think: .high)
        )

        let schema = JSONSchema(
            type: "object",
            properties: [
                "name": JSONSchemaProperty(type: "string", description: "Full name"),
                "age": JSONSchemaProperty(type: "integer"),
            ],
            required: ["name", "age"]
        )
        _ = try await client.chat(
            messages: [ChatMessage(role: .user, content: "x")],
            model: model,
            options: ChatOptions(format: .jsonSchema(schema))
        )

        _ = try await client.generateEmbeddings(
            input: .multiple(["a", "b"]),
            model: model,
            options: EmbeddingOptions(dimensions: 256)
        )

        let tools = [
            ToolDefinition(
                type: "function",
                function: FunctionDefinition(
                    name: "get_weather",
                    description: "Get current weather",
                    parameters: Parameters(
                        properties: [
                            "location": PropertyDefinition(type: "string", description: "City")
                        ],
                        required: ["location"]
                    )
                )
            )
        ]
        let stream = try await client.chat(
            messages: [ChatMessage(role: .user, content: "x")],
            model: model,
            options: ChatOptions(tools: tools)
        )
        for try await response in stream {
            for call in response.message.toolCalls ?? [] {
                _ = (call.function.name, call.id ?? "-", call.function.arguments)
            }
        }

        _ = try await client.completeText(prompt: "x", model: model)
        let reply = try await client.completeChat(
            messages: [ChatMessage(role: .user, content: "x")],
            model: model
        )
        _ = reply.content
        _ = try await client.generateText(prompt: "x", model: model).collect()

        let authed = OllamaClient(
            baseURL: URL(string: "https://ollama.example.com")!,
            configuration: OllamaConfiguration(apiKey: "your-api-key")
        )
        _ = authed.configuration.apiKey
    }
}
