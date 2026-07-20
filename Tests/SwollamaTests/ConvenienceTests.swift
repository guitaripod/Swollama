import Foundation
import XCTest

@testable import Swollama

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

final class OllamaModelNameConformanceTests: XCTestCase {

    func testDescriptionMatchesFullName() {
        let model = OllamaModelName(namespace: "library", name: "llama3.2", tag: "latest")
        XCTAssertEqual(model.description, model.fullName)
        XCTAssertEqual("\(model)", "library/llama3.2:latest")
    }

    func testEquatableAndHashable() {
        let a = OllamaModelName.parse("qwen3:0.6b")!
        let b = OllamaModelName.parse("qwen3:0.6b")!
        let c = OllamaModelName.parse("qwen3:1.7b")!
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)

        let set: Set<OllamaModelName> = [a, b, c]
        XCTAssertEqual(set.count, 2, "Equal names should collapse in a Set")
    }
}

final class OllamaErrorMappingTests: XCTestCase {

    func testSuccessMapsToNil() {
        XCTAssertNil(OllamaError.fromServer(statusCode: 200, body: nil))
        XCTAssertNil(OllamaError.fromServer(statusCode: 299, body: Data()))
    }

    func testParsesErrorField() {
        let body = #"{"error":"model 'x' not found, try pulling it first"}"#.data(using: .utf8)
        guard
            case .invalidParameters(let message)? = OllamaError.fromServer(
                statusCode: 400,
                body: body
            )
        else {
            return XCTFail("Expected invalidParameters")
        }
        XCTAssertEqual(message, "model 'x' not found, try pulling it first")
    }

    func testFallsBackToRawBody() {
        let body = "plain text failure".data(using: .utf8)
        guard case .serverError(let message)? = OllamaError.fromServer(statusCode: 500, body: body)
        else {
            return XCTFail("Expected serverError")
        }
        XCTAssertEqual(message, "plain text failure")
    }

    func testStatusCodeMapping() {
        guard case .modelNotFound? = OllamaError.fromServer(statusCode: 404, body: nil) else {
            return XCTFail("404 should map to modelNotFound")
        }
        guard case .authenticationFailed? = OllamaError.fromServer(statusCode: 401, body: nil)
        else {
            return XCTFail("401 should map to authenticationFailed")
        }
        guard case .authenticationFailed? = OllamaError.fromServer(statusCode: 403, body: nil)
        else {
            return XCTFail("403 should map to authenticationFailed")
        }
        guard
            case .rateLimited(let retryAfter)? = OllamaError.fromServer(
                statusCode: 429,
                body: nil,
                retryAfter: 12
            )
        else {
            return XCTFail("429 should map to rateLimited")
        }
        XCTAssertEqual(retryAfter, 12)
        guard
            case .unexpectedStatusCode(let code)? = OllamaError.fromServer(
                statusCode: 302,
                body: nil
            )
        else {
            return XCTFail("Unmapped codes should map to unexpectedStatusCode")
        }
        XCTAssertEqual(code, 302)
    }
}

final class BackoffTests: XCTestCase {

    func testBackoffGrowsAndCaps() {
        let base = 1.0
        let first = OllamaClient.backoffDelay(base: base, attempt: 0)
        XCTAssertGreaterThanOrEqual(first, 1.0)
        XCTAssertLessThanOrEqual(first, 1.0 + 1.0 * 0.25 + 0.0001)

        let large = OllamaClient.backoffDelay(base: base, attempt: 20)
        XCTAssertLessThanOrEqual(large, 30 + 30 * 0.25 + 0.0001, "Backoff must stay capped")
        XCTAssertGreaterThanOrEqual(large, 30)
    }

    func testRetryAfterParsing() {
        let response = HTTPURLResponse(
            url: URL(string: "http://localhost")!,
            statusCode: 429,
            httpVersion: "HTTP/1.1",
            headerFields: ["Retry-After": " 7 "]
        )!
        XCTAssertEqual(OllamaClient.retryAfterSeconds(from: response), 7)

        let none = HTTPURLResponse(
            url: URL(string: "http://localhost")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        XCTAssertNil(OllamaClient.retryAfterSeconds(from: none))
    }
}

final class AsyncCollectTests: XCTestCase {

    func testCollectGathersAllElements() async throws {
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            for value in 1...5 { continuation.yield(value) }
            continuation.finish()
        }
        let collected = try await stream.collect()
        XCTAssertEqual(collected, [1, 2, 3, 4, 5])
    }

    func testCollectPropagatesError() async {
        struct Boom: Error {}
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            continuation.yield(1)
            continuation.finish(throwing: Boom())
        }
        do {
            _ = try await stream.collect()
            XCTFail("Expected error to propagate")
        } catch is Boom {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
