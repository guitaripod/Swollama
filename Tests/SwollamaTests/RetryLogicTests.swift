import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import Swollama

final class RetryLogicTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.reset()
    }

    func testServerErrorRetriesUpToMaxRetries() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            let data = "Internal Server Error".data(using: .utf8)!
            return (response, data)
        }

        let client = createTestClient(maxRetries: 3, retryDelay: 0.01)
        let startTime = Date()

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown serverError")
        } catch let error as OllamaError {
            guard case .serverError = error else {
                XCTFail("Expected serverError, got \(error)")
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let expectedDelay = 0.01 * 3
            XCTAssertGreaterThan(elapsed, expectedDelay * 0.8, "Should have delayed for retries")
            XCTAssertEqual(MockURLProtocol.requestCount, 4, "Should attempt once + 3 retries = 4 total")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testModelNotFoundDoesNotRetry() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        let client = createTestClient(maxRetries: 3, retryDelay: 0.01)

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown modelNotFound")
        } catch let error as OllamaError {
            guard case .modelNotFound = error else {
                XCTFail("Expected modelNotFound, got \(error)")
                return
            }
            XCTAssertEqual(MockURLProtocol.requestCount, 1, "Should not retry on 404")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testInvalidParametersDoesNotRetry() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            let data = "Invalid request parameters".data(using: .utf8)!
            return (response, data)
        }

        let client = createTestClient(maxRetries: 3, retryDelay: 0.01)

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown invalidParameters")
        } catch let error as OllamaError {
            guard case .invalidParameters = error else {
                XCTFail("Expected invalidParameters, got \(error)")
                return
            }
            XCTAssertEqual(MockURLProtocol.requestCount, 1, "Should not retry on 400")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNetworkErrorRetries() async throws {
        MockURLProtocol.requestHandler = { request in
            throw URLError(.timedOut)
        }

        let client = createTestClient(maxRetries: 3, retryDelay: 0.01)

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown networkError")
        } catch let error as OllamaError {
            guard case .networkError = error else {
                XCTFail("Expected networkError, got \(error)")
                return
            }
            XCTAssertEqual(MockURLProtocol.requestCount, 4, "Should retry network errors")
        } catch let urlError as URLError {
            XCTAssertEqual(MockURLProtocol.requestCount, 4, "Should retry network errors")
            XCTAssertEqual(urlError.code, .timedOut)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSuccessOnRetryAttempt() async throws {
        var attemptCount = 0

        MockURLProtocol.requestHandler = { request in
            attemptCount += 1

            if attemptCount < 3 {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 500,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                return (response, Data())
            } else {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                let data = "{\"models\":[]}".data(using: .utf8)!
                return (response, data)
            }
        }

        let client = createTestClient(maxRetries: 3, retryDelay: 0.01)
        let result = try await client.listModels()

        XCTAssertNotNil(result)
        XCTAssertEqual(attemptCount, 3, "Should succeed on third attempt")
    }

    func testRetryDelayIsApplied() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, "Service Unavailable".data(using: .utf8)!)
        }

        let client = createTestClient(maxRetries: 2, retryDelay: 0.1)
        let startTime = Date()

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown")
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            let expectedMinDelay = 0.1 * 2
            XCTAssertGreaterThan(elapsed, expectedMinDelay * 0.8, "Should delay between retries")
        }
    }

    func testUnexpectedStatusCodeDoesNotRetry() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        let client = createTestClient(maxRetries: 3, retryDelay: 0.01)

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown")
        } catch let error as OllamaError {
            guard case .unexpectedStatusCode(let code) = error else {
                XCTFail("Expected unexpectedStatusCode, got \(error)")
                return
            }
            XCTAssertEqual(code, 429)
            XCTAssertEqual(MockURLProtocol.requestCount, 1, "Should not retry unexpected status codes")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testZeroRetriesDisablesRetry() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        let client = createTestClient(maxRetries: 0, retryDelay: 0.01)

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(MockURLProtocol.requestCount, 1, "Should not retry when maxRetries is 0")
        }
    }

    func testMultipleDifferentErrorsAcrossRetries() async throws {
        var attemptCount = 0
        let statusCodes = [500, 502, 503]

        MockURLProtocol.requestHandler = { request in
            let code = statusCodes[min(attemptCount, statusCodes.count - 1)]
            attemptCount += 1

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: code,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, "Error \(code)".data(using: .utf8)!)
        }

        let client = createTestClient(maxRetries: 3, retryDelay: 0.01)

        do {
            _ = try await client.listModels()
            XCTFail("Should have thrown")
        } catch let error as OllamaError {
            guard case .serverError(let message) = error else {
                XCTFail("Expected serverError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("503"), "Should report last error status")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func createTestClient(
        maxRetries: Int,
        retryDelay: TimeInterval
    ) -> OllamaClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]

        let session = URLSession(configuration: config)
        let ollamaConfig = OllamaConfiguration(
            timeoutInterval: 1.0,
            maxRetries: maxRetries,
            retryDelay: retryDelay
        )

        return OllamaClient(
            baseURL: URL(string: "http://localhost:11434")!,
            configuration: ollamaConfig,
            session: session
        )
    }
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var requestCount = 0

    static func reset() {
        requestHandler = nil
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        MockURLProtocol.requestCount += 1

        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
    }
}
