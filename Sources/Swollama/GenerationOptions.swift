import Foundation

/// Options for text generation
public struct GenerationOptions {
    public let suffix: String?
    public let images: [String]?
    public let format: ResponseFormat?
    public let modelOptions: ModelOptions?
    public let systemPrompt: String?
    public let template: String?
    public let context: [Int]?
    public let raw: Bool?
    public let keepAlive: TimeInterval?
    public let think: Bool?

    public init(
        suffix: String? = nil,
        images: [String]? = nil,
        format: ResponseFormat? = nil,
        modelOptions: ModelOptions? = nil,
        systemPrompt: String? = nil,
        template: String? = nil,
        context: [Int]? = nil,
        raw: Bool? = nil,
        keepAlive: TimeInterval? = nil,
        think: Bool? = nil
    ) {
        self.suffix = suffix
        self.images = images
        self.format = format
        self.modelOptions = modelOptions
        self.systemPrompt = systemPrompt
        self.template = template
        self.context = context
        self.raw = raw
        self.keepAlive = keepAlive
        self.think = think
    }

    public static let `default` = GenerationOptions()
}
