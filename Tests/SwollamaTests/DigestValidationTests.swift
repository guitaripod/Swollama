import XCTest

@testable import Swollama

final class DigestValidationTests: XCTestCase {

    var client: OllamaClient!

    override func setUp() async throws {
        client = OllamaClient()
    }

    func testInvalidDigestTooShort() async {
        let invalidDigest = "sha256:" + String(repeating: "a", count: 63)
        do {
            _ = try await client.checkBlobExists(digest: invalidDigest)
            XCTFail("Should reject digest that's too short")
        } catch OllamaError.invalidParameters {
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidDigestInvalidHexChar() async {
        let invalidDigest = "sha256:" + String(repeating: "z", count: 64)
        do {
            _ = try await client.checkBlobExists(digest: invalidDigest)
            XCTFail("Should reject digest with invalid hex characters")
        } catch OllamaError.invalidParameters {
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidDigestPathTraversal() async {
        let invalidDigest = "../../../etc/passwd"
        do {
            _ = try await client.checkBlobExists(digest: invalidDigest)
            XCTFail("Should reject path traversal attempt")
        } catch OllamaError.invalidParameters {
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidDigestNoHash() async {
        let invalidDigest = "sha256:"
        do {
            _ = try await client.checkBlobExists(digest: invalidDigest)
            XCTFail("Should reject digest without hash")
        } catch OllamaError.invalidParameters {
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidDigestNoAlgorithm() async {
        let invalidDigest = ":" + String(repeating: "a", count: 64)
        do {
            _ = try await client.checkBlobExists(digest: invalidDigest)
            XCTFail("Should reject digest without algorithm")
        } catch OllamaError.invalidParameters {
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidDigestWrongAlgorithm() async {
        let invalidDigest = "md5:" + String(repeating: "a", count: 32)
        do {
            _ = try await client.checkBlobExists(digest: invalidDigest)
            XCTFail("Should reject unsupported algorithm")
        } catch OllamaError.invalidParameters {
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPushBlobWithInvalidDigest() async {
        let invalidDigest = "invalid"
        let data = Data("test".utf8)
        do {
            try await client.pushBlob(digest: invalidDigest, data: data)
            XCTFail("Should reject invalid digest in pushBlob")
        } catch OllamaError.invalidParameters {
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testDigestValidationErrorMessage() async {
        let invalidDigest = "invalid"
        do {
            _ = try await client.checkBlobExists(digest: invalidDigest)
            XCTFail("Should throw error")
        } catch OllamaError.invalidParameters(let message) {
            XCTAssertTrue(message.contains("Invalid digest format"))
            XCTAssertTrue(message.contains("sha256") || message.contains("sha512"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
