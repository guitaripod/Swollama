import Foundation
import Swollama

extension OllamaError {
    /// A user-facing description of the error, adding model context where it helps the user act.
    func cliDescription(model: OllamaModelName) -> String {
        switch self {
        case .modelNotFound:
            return
                "Model '\(model.fullName)' not found. Please check the model name and try again."
        default:
            return errorDescription ?? "An unknown error occurred"
        }
    }
}
