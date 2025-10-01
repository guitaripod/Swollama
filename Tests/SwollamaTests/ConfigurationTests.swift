import XCTest

@testable import Swollama

final class ConfigurationTests: XCTestCase {

    func testDefaultConfiguration() {
        let config = OllamaConfiguration.default

        XCTAssertEqual(config.timeoutInterval, 30)
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertEqual(config.retryDelay, 1)
        XCTAssertFalse(config.allowsInsecureConnections)
        XCTAssertEqual(config.defaultKeepAlive, 300)
    }

    func testCustomConfiguration() {
        let config = OllamaConfiguration(
            timeoutInterval: 60,
            maxRetries: 5,
            retryDelay: 2,
            allowsInsecureConnections: true,
            defaultKeepAlive: 600
        )

        XCTAssertEqual(config.timeoutInterval, 60)
        XCTAssertEqual(config.maxRetries, 5)
        XCTAssertEqual(config.retryDelay, 2)
        XCTAssertTrue(config.allowsInsecureConnections)
        XCTAssertEqual(config.defaultKeepAlive, 600)
    }

    func testClientWithDefaultConfiguration() async {
        let client = OllamaClient()

        XCTAssertEqual(client.configuration.timeoutInterval, 30)
        XCTAssertEqual(client.configuration.maxRetries, 3)
    }

    func testClientWithCustomConfiguration() async {
        let config = OllamaConfiguration(
            timeoutInterval: 120,
            maxRetries: 1,
            retryDelay: 0.5
        )
        let client = OllamaClient(configuration: config)

        XCTAssertEqual(client.configuration.timeoutInterval, 120)
        XCTAssertEqual(client.configuration.maxRetries, 1)
        XCTAssertEqual(client.configuration.retryDelay, 0.5)
    }

    func testClientWithCustomBaseURL() async throws {
        let customURL = URL(string: "http://custom-ollama:11434")!
        let client = OllamaClient(baseURL: customURL)

        let baseURL = await client.baseURL
        XCTAssertEqual(baseURL, customURL)
    }

    func testClientDefaultBaseURL() async {
        let client = OllamaClient()

        let baseURL = await client.baseURL
        XCTAssertEqual(baseURL.absoluteString, "http://localhost:11434")
    }

    func testConfigurationIsValueType() {
        let config1 = OllamaConfiguration.default
        var config2 = config1

        config2 = OllamaConfiguration(
            timeoutInterval: 60,
            maxRetries: 5,
            retryDelay: 2,
            allowsInsecureConnections: true,
            defaultKeepAlive: 600
        )

        XCTAssertEqual(config1.timeoutInterval, 30)
        XCTAssertEqual(config2.timeoutInterval, 60)
    }
}
