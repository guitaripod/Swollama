import XCTest

@testable import Swollama

final class ErrorHandlingTests: XCTestCase {

    func testOllamaErrorTypes() {
        let errors: [OllamaError] = [
            .invalidResponse,
            .decodingError(NSError(domain: "test", code: 1)),
            .serverError("500 Internal Server Error"),
            .modelNotFound,
            .cancelled,
            .networkError(NSError(domain: "test", code: 2)),
            .unexpectedStatusCode(418),
            .invalidParameters("Bad request"),
            .fileError("File not found"),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testDecodingErrorDescription() {
        let underlyingError = NSError(
            domain: "JSONDecoder",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid JSON"
            ]
        )
        let error = OllamaError.decodingError(underlyingError)

        XCTAssertTrue(error.errorDescription!.contains("decode"))
        XCTAssertTrue(error.errorDescription!.contains("Invalid JSON"))
    }

    func testServerErrorDescription() {
        let error = OllamaError.serverError("Model not loaded")

        XCTAssertTrue(error.errorDescription!.contains("Server error"))
        XCTAssertTrue(error.errorDescription!.contains("Model not loaded"))
    }

    func testInvalidParametersDescription() {
        let error = OllamaError.invalidParameters("Temperature must be between 0 and 1")

        XCTAssertTrue(error.errorDescription!.contains("Invalid parameters"))
        XCTAssertTrue(error.errorDescription!.contains("Temperature"))
    }

    func testUnexpectedStatusCodeDescription() {
        let error = OllamaError.unexpectedStatusCode(418)

        XCTAssertTrue(error.errorDescription!.contains("418"))
    }

    func testModelNotFoundDescription() {
        let error = OllamaError.modelNotFound

        XCTAssertTrue(error.errorDescription!.contains("not found"))
    }

    func testNetworkErrorDescription() {
        let underlyingError = URLError(.timedOut)
        let error = OllamaError.networkError(underlyingError)

        XCTAssertTrue(error.errorDescription!.contains("Network error"))
    }
}
