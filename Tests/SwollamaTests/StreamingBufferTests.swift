import XCTest

@testable import Swollama

final class StreamingBufferTests: XCTestCase {

    func testBufferHandlesMultipleCompleteLines() {
        var buffer = Data()
        let newline = UInt8(ascii: "\n")
        var lines: [Data] = []

        let input = "line1\nline2\nline3\n".data(using: .utf8)!
        buffer.append(input)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }

        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(String(data: lines[0], encoding: .utf8), "line1")
        XCTAssertEqual(String(data: lines[1], encoding: .utf8), "line2")
        XCTAssertEqual(String(data: lines[2], encoding: .utf8), "line3")
        XCTAssertTrue(buffer.isEmpty)
    }

    func testBufferHandlesPartialLine() {
        var buffer = Data()
        let newline = UInt8(ascii: "\n")
        var lines: [Data] = []

        let input = "complete\npartial".data(using: .utf8)!
        buffer.append(input)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(String(data: lines[0], encoding: .utf8), "complete")
        XCTAssertEqual(String(data: buffer, encoding: .utf8), "partial")
    }

    func testBufferHandlesEmptyLines() {
        var buffer = Data()
        let newline = UInt8(ascii: "\n")
        var lines: [Data] = []

        let input = "line1\n\nline2\n".data(using: .utf8)!
        buffer.append(input)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(data: lines[0], encoding: .utf8), "line1")
        XCTAssertEqual(String(data: lines[1], encoding: .utf8), "line2")
    }

    func testBufferHandlesChunkedInput() {
        var buffer = Data()
        let newline = UInt8(ascii: "\n")
        var lines: [Data] = []

        let chunk1 = "partial".data(using: .utf8)!
        buffer.append(chunk1)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }
        XCTAssertEqual(lines.count, 0)

        let chunk2 = "line\ncompl".data(using: .utf8)!
        buffer.append(chunk2)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(String(data: lines[0], encoding: .utf8), "partialline")

        let chunk3 = "ete\n".data(using: .utf8)!
        buffer.append(chunk3)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(data: lines[1], encoding: .utf8), "complete")
    }

    func testBufferHandlesOnlyNewlines() {
        var buffer = Data()
        let newline = UInt8(ascii: "\n")
        var lines: [Data] = []

        let input = "\n\n\n".data(using: .utf8)!
        buffer.append(input)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }

        XCTAssertEqual(lines.count, 0)
        XCTAssertTrue(buffer.isEmpty)
    }

    func testBufferHandlesJSONStreaming() throws {
        struct TestResponse: Codable {
            let message: String
            let done: Bool
        }

        var buffer = Data()
        let newline = UInt8(ascii: "\n")
        var responses: [TestResponse] = []
        let decoder = JSONDecoder()

        let jsonStream = """
            {"message":"Hello","done":false}
            {"message":" world","done":false}
            {"message":"!","done":true}
            """.data(using: .utf8)!

        buffer.append(jsonStream)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                let response = try decoder.decode(TestResponse.self, from: lineData)
                responses.append(response)
            }
            buffer.removeSubrange(...newlineIndex)
        }

        XCTAssertGreaterThan(responses.count, 0)
        XCTAssertEqual(responses[0].message, "Hello")
        XCTAssertFalse(responses[0].done)
        if responses.count > 1 {
            XCTAssertEqual(responses[1].message, " world")
            XCTAssertFalse(responses[1].done)
        }
        if responses.count > 2 {
            XCTAssertEqual(responses[2].message, "!")
            XCTAssertTrue(responses[2].done)
        }
    }

    func testBufferHandlesPartialJSON() {
        var buffer = Data()

        let partial1 = "{\"message\":\"Hel".data(using: .utf8)!
        buffer.append(partial1)

        XCTAssertEqual(String(data: buffer, encoding: .utf8), "{\"message\":\"Hel")

        let partial2 = "lo\"}".data(using: .utf8)!
        buffer.append(partial2)

        XCTAssertEqual(String(data: buffer, encoding: .utf8), "{\"message\":\"Hello\"}")
    }

    func testBufferHandlesUnicodeCorrectly() {
        var buffer = Data()
        let newline = UInt8(ascii: "\n")
        var lines: [Data] = []

        let input = "Hello 👋\nWorld 🌍\n".data(using: .utf8)!
        buffer.append(input)

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer[..<newlineIndex]
            if !lineData.isEmpty {
                lines.append(lineData)
            }
            buffer.removeSubrange(...newlineIndex)
        }

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(data: lines[0], encoding: .utf8), "Hello 👋")
        XCTAssertEqual(String(data: lines[1], encoding: .utf8), "World 🌍")
    }
}
