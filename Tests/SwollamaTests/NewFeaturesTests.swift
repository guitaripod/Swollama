import XCTest
@testable import Swollama

final class NewFeaturesTests: XCTestCase {
    
    func testStructuredOutputTypes() throws {
        // Test JSON Schema creation
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
        
        // Test ResponseFormat enum
        let jsonFormat = ResponseFormat.json
        let schemaFormat = ResponseFormat.jsonSchema(schema)
        
        // Verify they're different
        XCTAssertNotNil(jsonFormat)
        XCTAssertNotNil(schemaFormat)
    }
    
    func testThinkingModelSupport() throws {
        // Test GenerateRequest with think parameter
        let generateRequest = GenerateRequest(
            model: "deepseek-r1",
            prompt: "Solve this problem",
            think: true
        )
        XCTAssertEqual(generateRequest.think, true)
        
        // Test ChatRequest with think parameter
        let chatRequest = ChatRequest(
            model: "deepseek-r1",
            messages: [
                ChatMessage(role: .user, content: "Hello", thinking: nil)
            ],
            think: true
        )
        XCTAssertEqual(chatRequest.think, true)
        
        // Test ChatMessage with thinking field
        let messageWithThinking = ChatMessage(
            role: .assistant,
            content: "The answer is 42",
            thinking: "Let me think step by step..."
        )
        XCTAssertEqual(messageWithThinking.thinking, "Let me think step by step...")
    }
    
    func testCreateModelRequest() throws {
        // Test basic model creation
        let basicRequest = CreateModelRequest(
            model: "custom-model",
            from: "llama3.2",
            system: "You are a helpful assistant"
        )
        XCTAssertEqual(basicRequest.model, "custom-model")
        XCTAssertEqual(basicRequest.from, "llama3.2")
        
        // Test with quantization
        let quantizeRequest = CreateModelRequest(
            model: "llama3.2:q4",
            from: "llama3.2:fp16",
            quantize: .q4_K_M
        )
        XCTAssertEqual(quantizeRequest.quantize, .q4_K_M)
        
        // Test with files (GGUF)
        let ggufRequest = CreateModelRequest(
            model: "my-gguf",
            files: ["model.gguf": "sha256:abc123..."]
        )
        XCTAssertNotNil(ggufRequest.files)
        
        // Test with parameters
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
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test single string
        let singleLicense = StringOrArray.string("MIT")
        let singleData = try encoder.encode(singleLicense)
        let decodedSingle = try decoder.decode(StringOrArray.self, from: singleData)
        
        switch decodedSingle {
        case .string(let value):
            XCTAssertEqual(value, "MIT")
        case .array:
            XCTFail("Expected string, got array")
        }
        
        // Test array
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
        
        // Test boolean
        let boolValue = JSONSchemaPropertyOrBool.bool(true)
        let boolData = try encoder.encode(boolValue)
        let decodedBool = try decoder.decode(JSONSchemaPropertyOrBool.self, from: boolData)
        
        switch decodedBool {
        case .bool(let value):
            XCTAssertEqual(value, true)
        case .property:
            XCTFail("Expected bool, got property")
        }
        
        // Test property
        let prop = JSONSchemaProperty(type: "string")
        let propValue = JSONSchemaPropertyOrBool.property(prop)
        let propData = try encoder.encode(propValue)
        let decodedProp = try decoder.decode(JSONSchemaPropertyOrBool.self, from: propData)
        
        switch decodedProp {
        case .bool:
            XCTFail("Expected property, got bool")
        case .property(let value):
            XCTAssertEqual(value.type, "string")
        }
    }
    
    func testAdvancedGenerationOptions() throws {
        // Test suffix parameter
        let suffixRequest = GenerateRequest(
            model: "codellama",
            prompt: "def hello():",
            suffix: "\n\nprint(hello())"
        )
        XCTAssertEqual(suffixRequest.suffix, "\n\nprint(hello())")
        
        // Test raw mode
        let rawRequest = GenerateRequest(
            model: "mistral",
            prompt: "[INST] Hello [/INST]",
            raw: true
        )
        XCTAssertEqual(rawRequest.raw, true)
        
        // Test images
        let imageRequest = GenerateRequest(
            model: "llava",
            prompt: "What's in this image?",
            images: ["base64encodedimage..."]
        )
        XCTAssertEqual(imageRequest.images?.count, 1)
    }
}