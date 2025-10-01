import XCTest
@testable import Swollama

final class ModelNameParsingTests: XCTestCase {

    func testParseBasicModelName() {
        let model = OllamaModelName.parse("llama3.2")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "llama3.2")
        XCTAssertEqual(model?.tag, "latest")
        XCTAssertNil(model?.namespace)
    }

    func testParseModelNameWithTag() {
        let model = OllamaModelName.parse("llama3.2:13b")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "llama3.2")
        XCTAssertEqual(model?.tag, "13b")
        XCTAssertNil(model?.namespace)
    }

    func testParseModelNameWithNamespace() {
        let model = OllamaModelName.parse("anthropic/claude")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "claude")
        XCTAssertEqual(model?.namespace, "anthropic")
        XCTAssertEqual(model?.tag, "latest")
    }

    func testParseModelNameWithNamespaceAndTag() {
        let model = OllamaModelName.parse("anthropic/claude:3.5")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "claude")
        XCTAssertEqual(model?.namespace, "anthropic")
        XCTAssertEqual(model?.tag, "3.5")
    }

    func testParseEmptyString() {
        let model = OllamaModelName.parse("")
        XCTAssertNil(model)
    }

    func testParseOnlyColon() {
        let model = OllamaModelName.parse(":")
        XCTAssertNil(model)
    }

    func testParseOnlySlash() {
        let model = OllamaModelName.parse("/")
        XCTAssertNil(model)
    }

    func testParseMultipleSlashes() {
        let model = OllamaModelName.parse("a/b/c")
        XCTAssertNil(model)
    }

    func testParseColonOnly() {
        let model = OllamaModelName.parse(":tag")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "tag")
        XCTAssertEqual(model?.tag, "latest")
    }

    func testParseNamespaceWithoutModel() {
        let model = OllamaModelName.parse("namespace/")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "namespace")
        XCTAssertEqual(model?.tag, "latest")
    }

    func testParseNamespaceWithColonOnly() {
        let model = OllamaModelName.parse("namespace/:")
        XCTAssertNil(model)
    }

    func testFullNameBasic() {
        let model = OllamaModelName(name: "llama3.2", tag: "latest")
        XCTAssertEqual(model.fullName, "llama3.2:latest")
    }

    func testFullNameWithNamespace() {
        let model = OllamaModelName(namespace: "anthropic", name: "claude", tag: "3.5")
        XCTAssertEqual(model.fullName, "anthropic/claude:3.5")
    }

    func testParseAndRoundtrip() {
        let original = "anthropic/claude:3.5"
        let model = OllamaModelName.parse(original)
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.fullName, original)
    }

    func testParseWithSpecialCharacters() {
        let model = OllamaModelName.parse("model-name_v2.1")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "model-name_v2.1")
    }
}
