import Foundation

/// Detailed information about a specific model.
///
/// Contains the model's configuration including modelfile, parameters, prompt template, and technical details.
public struct ModelInformation: Codable, Sendable {
    /// The modelfile content that defines the model.
    public let modelfile: String

    /// Model parameters as a string (if available).
    public let parameters: String?

    /// The prompt template used by the model.
    public let template: String

    /// Technical details about the model's architecture.
    public let details: ModelDetails

    private enum CodingKeys: String, CodingKey {
        case modelfile, parameters, template, details
    }
}
