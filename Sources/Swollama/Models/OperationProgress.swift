import Foundation

/// Progress information for long-running operations.
///
/// Used to track the progress of model pulls, pushes, and creation operations.
public struct OperationProgress: Codable, Sendable {
    public init(status: String, digest: String? = nil, total: UInt64? = nil, completed: UInt64? = nil) {
        self.status = status
        self.digest = digest
        self.total = total
        self.completed = completed
    }

    /// Status message describing the current operation phase.
    public let status: String

    /// The digest of the layer being processed (for pull/push operations).
    public let digest: String?

    /// Total size in bytes.
    public let total: UInt64?

    /// Completed size in bytes.
    public let completed: UInt64?
}
