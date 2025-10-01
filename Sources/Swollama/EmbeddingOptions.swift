import Foundation


public struct EmbeddingOptions {
    public let truncate: Bool?
    public let modelOptions: ModelOptions?
    public let keepAlive: TimeInterval?

    public init(
        truncate: Bool? = true,
        modelOptions: ModelOptions? = nil,
        keepAlive: TimeInterval? = nil
    ) {
        self.truncate = truncate
        self.modelOptions = modelOptions
        self.keepAlive = keepAlive
    }

    public static let `default` = EmbeddingOptions()
}
