import XCTest
@testable import Swollama

final class AgentTests: XCTestCase {
    func testAgentConfiguration() {
        let defaultConfig = AgentConfiguration.default
        XCTAssertEqual(defaultConfig.maxIterations, 10)
        XCTAssertEqual(defaultConfig.truncateResults, 8000)
        XCTAssertTrue(defaultConfig.enableThinking)

        let fastConfig = AgentConfiguration.fast
        XCTAssertEqual(fastConfig.maxIterations, 5)
        XCTAssertEqual(fastConfig.truncateResults, 4000)
        XCTAssertFalse(fastConfig.enableThinking)
    }

    func testAgentEventDescription() {
        let thinkingEvent = AgentEvent.thinking("test thought")
        XCTAssert(thinkingEvent.description.contains("Thinking"))

        let toolCallEvent = AgentEvent.toolCall(name: "test_tool", arguments: "{}")
        XCTAssert(toolCallEvent.description.contains("Tool Call"))

        let messageEvent = AgentEvent.message("test message")
        XCTAssert(messageEvent.description.contains("Message"))
    }
}
