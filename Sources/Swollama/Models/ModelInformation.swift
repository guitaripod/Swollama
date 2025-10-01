import Foundation


public struct ModelInformation: Codable, Sendable {

    public let modelfile: String

    public let parameters: String?

    public let template: String

    public let details: ModelDetails

    private enum CodingKeys: String, CodingKey {
        case modelfile, parameters, template, details
    }
}
