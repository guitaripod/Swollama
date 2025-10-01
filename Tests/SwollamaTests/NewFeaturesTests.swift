import XCTest
@testable import Swollama

final class NewFeaturesTests: XCTestCase {

    func testStructuredOutputTypes() throws {

        let schema = JSONSchema(
            type: "object",
            properties: [
                "name": JSONSchemaProperty(type: "string", description: "User name"),
                "age": JSONSchemaProperty(type: "integer"),
                "tags": JSONSchemaProperty(
                    type: "array",
                    items: JSONSchemaProperty(type: "string")
                ),
                "metadata": JSONSchemaProperty(
                    type: "object",
                    properties: [
                        "created": JSONSchemaProperty(type: "string"),
                        "version": JSONSchemaProperty(type: "integer")
                    ]
                )
            ],
            required: ["name", "age"]
        )


        let jsonFormat = ResponseFormat.json
        let schemaFormat = ResponseFormat.jsonSchema(schema)


        XCTAssertNotNil(jsonFormat)
        XCTAssertNotNil(schemaFormat)
    }

    func testThinkingModelSupport() throws {

        let generateRequest = GenerateRequest(
            model: "deepseek-r1",
            prompt: "Solve this problem",
            think: true
        )
        XCTAssertEqual(generateRequest.think, true)


        let chatRequest = ChatRequest(
            model: "deepseek-r1",
            messages: [
                ChatMessage(role: .user, content: "Hello", thinking: nil)
            ],
            think: true
        )
        XCTAssertEqual(chatRequest.think, true)


        let messageWithThinking = ChatMessage(
            role: .assistant,
            content: "The answer is 42",
            thinking: "Let me think step by step..."
        )
        XCTAssertEqual(messageWithThinking.thinking, "Let me think step by step...")
    }

    func testCreateModelRequest() throws {

        let basicRequest = CreateModelRequest(
            model: "custom-model",
            from: "llama3.2",
            system: "You are a helpful assistant"
        )
        XCTAssertEqual(basicRequest.model, "custom-model")
        XCTAssertEqual(basicRequest.from, "llama3.2")


        let quantizeRequest = CreateModelRequest(
            model: "llama3.2:q4",
            from: "llama3.2:fp16",
            quantize: .q4_K_M
        )
        XCTAssertEqual(quantizeRequest.quantize, .q4_K_M)


        let ggufRequest = CreateModelRequest(
            model: "my-gguf",
            files: ["model.gguf": "sha256:abc123..."]
        )
        XCTAssertNotNil(ggufRequest.files)


        let params = ModelfileParameters(
            temperature: 0.7,
            topK: 40,
            topP: 0.9
        )
        let paramRequest = CreateModelRequest(
            model: "configured",
            from: "base",
            parameters: params
        )
        XCTAssertEqual(paramRequest.parameters?.temperature, 0.7)
    }

    func testShowModelRequest() throws {
        let request = ShowModelRequest(
            model: "llama3.2",
            verbose: true
        )
        XCTAssertEqual(request.model, "llama3.2")
        XCTAssertEqual(request.verbose, true)
    }

    func testVersionResponse() throws {
        let response = VersionResponse(version: "0.5.1")
        XCTAssertEqual(response.version, "0.5.1")
    }

    func testQuantizationTypes() throws {
        XCTAssertEqual(QuantizationType.q4_K_M.rawValue, "q4_K_M")
        XCTAssertEqual(QuantizationType.q4_K_S.rawValue, "q4_K_S")
        XCTAssertEqual(QuantizationType.q8_0.rawValue, "q8_0")
    }

    func testStringOrArray() throws {

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()


        let singleLicense = StringOrArray.string("MIT")
        let singleData = try encoder.encode(singleLicense)
        let decodedSingle = try decoder.decode(StringOrArray.self, from: singleData)

        switch decodedSingle {
        case .string(let value):
            XCTAssertEqual(value, "MIT")
        case .array:
            XCTFail("Expected string, got array")
        }


        let multiLicense = StringOrArray.array(["MIT", "Apache-2.0"])
        let multiData = try encoder.encode(multiLicense)
        let decodedMulti = try decoder.decode(StringOrArray.self, from: multiData)

        switch decodedMulti {
        case .string:
            XCTFail("Expected array, got string")
        case .array(let values):
            XCTAssertEqual(values, ["MIT", "Apache-2.0"])
        }
    }

    func testJSONSchemaPropertyOrBool() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()


        let boolValue = JSONSchemaPropertyOrBool.bool(true)
        let boolData = try encoder.encode(boolValue)
        let decodedBool = try decoder.decode(JSONSchemaPropertyOrBool.self, from: boolData)

        switch decodedBool {
        case .bool(let value):
            XCTAssertEqual(value, true)
        case .property:
            XCTFail("Expected bool, got property")
        }


        let prop = JSONSchemaProperty(type: "string")
        let propValue = JSONSchemaPropertyOrBool.property(prop)
        let propData = try encoder.encode(propValue)
        let decodedProp = try decoder.decode(JSONSchemaPropertyOrBool.self, from: propData)

        switch decodedProp {
        case .bool:
            XCTFail("Expected property, got bool")
        case .property(let value):
            switch value {
            case .simple(let type, _, _):
                XCTAssertEqual(type, "string")
            default:
                XCTFail("Expected simple property")
            }
        }
    }

    func testAdvancedGenerationOptions() throws {

        let suffixRequest = GenerateRequest(
            model: "codellama",
            prompt: "def hello():",
            suffix: "\n\nprint(hello())"
        )
        XCTAssertEqual(suffixRequest.suffix, "\n\nprint(hello())")


        let rawRequest = GenerateRequest(
            model: "mistral",
            prompt: "[INST] Hello [/INST]",
            raw: true
        )
        XCTAssertEqual(rawRequest.raw, true)


        let imageRequest = GenerateRequest(
            model: "llava",
            prompt: "What's in this image?",
            images: ["base64encodedimage..."]
        )
        XCTAssertEqual(imageRequest.images?.count, 1)
    }
}