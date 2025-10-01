import Foundation


public struct AgentConfiguration: Sendable {
    public let maxIterations: Int

    public let truncateResults: Int?

    public let enableThinking: Bool

    public let modelOptions: ModelOptions?

    public init(
        maxIterations: Int = 10,
        truncateResults: Int? = 8000,
        enableThinking: Bool = true,
        modelOptions: ModelOptions? = nil
    ) {
        self.maxIterations = maxIterations
        self.truncateResults = truncateResults
        self.enableThinking = enableThinking
        self.modelOptions = modelOptions
    }

    public static let `default` = AgentConfiguration()

    public static let extended = AgentConfiguration(
        maxIterations: 20,
        truncateResults: 16000,
        enableThinking: true,
        modelOptions: ModelOptions(numCtx: 32000)
    )

    public static let fast = AgentConfiguration(
        maxIterations: 5,
        truncateResults: 4000,
        enableThinking: false,
        modelOptions: ModelOptions(temperature: 0.0)
    )
}
