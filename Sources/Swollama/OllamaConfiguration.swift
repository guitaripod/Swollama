import Foundation


public struct OllamaConfiguration {

    public let timeoutInterval: TimeInterval


    public let maxRetries: Int


    public let retryDelay: TimeInterval


    public let allowsInsecureConnections: Bool


    public let defaultKeepAlive: TimeInterval








    public init(
        timeoutInterval: TimeInterval = 30,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1,
        allowsInsecureConnections: Bool = false,
        defaultKeepAlive: TimeInterval = 300
    ) {
        self.timeoutInterval = timeoutInterval
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.allowsInsecureConnections = allowsInsecureConnections
        self.defaultKeepAlive = defaultKeepAlive
    }


    public static let `default` = OllamaConfiguration()
}
