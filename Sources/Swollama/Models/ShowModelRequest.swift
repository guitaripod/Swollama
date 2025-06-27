import Foundation

/// Parameters for showing model information
public struct ShowModelRequest: Codable, Sendable {
    /// Name of the model to show
    public let model: String
    /// If true, returns full data for verbose response fields
    public let verbose: Bool?
    
    public init(model: String, verbose: Bool? = nil) {
        self.model = model
        self.verbose = verbose
    }
}