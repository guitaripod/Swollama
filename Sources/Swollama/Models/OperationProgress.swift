import Foundation


public struct OperationProgress: Codable, Sendable {
    public init(status: String, digest: String? = nil, total: UInt64? = nil, completed: UInt64? = nil) {
        self.status = status
        self.digest = digest
        self.total = total
        self.completed = completed
    }


    public let status: String

    public let digest: String?

    public let total: UInt64?

    public let completed: UInt64?
}
