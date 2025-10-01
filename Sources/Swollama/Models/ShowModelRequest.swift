import Foundation


public struct ShowModelRequest: Codable, Sendable {

    public let model: String

    public let verbose: Bool?

    public init(model: String, verbose: Bool? = nil) {
        self.model = model
        self.verbose = verbose
    }
}