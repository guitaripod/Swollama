import Foundation
import Swollama

/// Protocol for tracking operation progress
protocol ProgressTracker {
    /// Tracks the progress of an asynchronous operation
    /// - Parameter progress: An async stream of progress updates
    func track(_ progress: AsyncThrowingStream<OperationProgress, Error>) async throws
}

/// Represents a part of a download operation with progress tracking
struct DownloadPart: Identifiable {
    let id: String // digest
    let total: UInt64
    var completed: UInt64
    let status: String
    let speedCalculator: SpeedCalculator
    var lastUpdateTime: Date
    var lastRenderedProgress: Double

    var progress: Double {
        Double(completed) / Double(total) * 100.0
    }

    var isComplete: Bool {
        completed == total
    }
}

/// High-performance progress tracker optimized for Linux terminals
struct DefaultProgressTracker: ProgressTracker {
    // MARK: - Constants
    
    private enum Constants {
        static let discoveryTimeout: TimeInterval = 0.5
        static let minBarWidth = 50
        static let digestDisplayLength = 8
        // Limit updates to 10 FPS for better performance
        static let minUpdateInterval: TimeInterval = 0.1
        // Only update if progress changed by at least 0.1%
        static let minProgressChange: Double = 0.1
    }
    
    // MARK: - Properties
    
    private let terminalHelper: TerminalHelper
    
    // MARK: - Initialization
    
    init(terminalHelper: TerminalHelper = CachedTerminalHelper()) {
        self.terminalHelper = terminalHelper
    }
    
    // MARK: - ProgressTracker Implementation
    
    func track(_ progress: AsyncThrowingStream<OperationProgress, Error>) async throws {
        let barWidth = calculateBarWidth()
        var parts: [String: DownloadPart] = [:]
        
        try await handleInitialDiscovery(progress, parts: &parts, barWidth: barWidth)
    }
    
    // MARK: - Private Helpers
    
    private func calculateBarWidth() -> Int {
        min(terminalHelper.terminalWidth - 65, Constants.minBarWidth)
    }
    
    private func handleInitialDiscovery(
        _ progress: AsyncThrowingStream<OperationProgress, Error>,
        parts: inout [String: DownloadPart],
        barWidth: Int
    ) async throws {
        var updates: [OperationProgress] = []
        let discoveryStart = Date()
        
        // Initial discovery phase
        for try await update in progress {
            updates.append(update)
            
            if let newPart = createPartIfNeeded(from: update) {
                parts[newPart.id] = newPart
                drawPart(newPart, barWidth: barWidth)
            }
            
            // Break after timeout
            if Date().timeIntervalSince(discoveryStart) > Constants.discoveryTimeout {
                break
            }
        }
        
        // Process buffered updates and continue tracking
        await processUpdates(updates, parts: &parts, barWidth: barWidth)
        try await continueTracking(progress, parts: &parts, barWidth: barWidth)
    }
    
    private func createPartIfNeeded(from update: OperationProgress) -> DownloadPart? {
        guard let digest = update.digest,
              let total = update.total else { return nil }
        
        return DownloadPart(
            id: digest,
            total: total,
            completed: update.completed ?? 0,
            status: update.status,
            speedCalculator: MovingAverageSpeedCalculator(),
            lastUpdateTime: Date(),
            lastRenderedProgress: 0
        )
    }
    
    private func processUpdates(
        _ updates: [OperationProgress],
        parts: inout [String: DownloadPart],
        barWidth: Int
    ) async {
        for update in updates {
            processUpdate(update, parts: &parts, barWidth: barWidth)
        }
    }
    
    private func continueTracking(
        _ progress: AsyncThrowingStream<OperationProgress, Error>,
        parts: inout [String: DownloadPart],
        barWidth: Int
    ) async throws {
        for try await update in progress {
            processUpdate(update, parts: &parts, barWidth: barWidth)
        }
    }
    
    private func processUpdate(
        _ update: OperationProgress,
        parts: inout [String: DownloadPart],
        barWidth: Int
    ) {
        guard let digest = update.digest,
              let completed = update.completed else { return }
        
        if var part = parts[digest] {
            part.completed = completed
            
            // Rate limit updates
            let now = Date()
            let timeSinceLastUpdate = now.timeIntervalSince(part.lastUpdateTime)
            let progressDelta = abs(part.progress - part.lastRenderedProgress)
            
            // Only update if enough time passed AND progress changed significantly
            if timeSinceLastUpdate >= Constants.minUpdateInterval &&
               (progressDelta >= Constants.minProgressChange || part.isComplete) {
                part.lastUpdateTime = now
                part.lastRenderedProgress = part.progress
                parts[digest] = part
                updatePartProgress(part, barWidth: barWidth)
            } else {
                // Still update internal state, just don't render
                parts[digest] = part
            }
        } else if let newPart = createPartIfNeeded(from: update) {
            parts[digest] = newPart
            drawPart(newPart, barWidth: barWidth)
        }
    }
    
    private func drawPart(_ part: DownloadPart, barWidth: Int) {
        let progressBar = createProgressBar(for: part, barWidth: barWidth)
        print(progressBar)
    }
    
    private func updatePartProgress(_ part: DownloadPart, barWidth: Int) {
        let progressBar = createProgressBar(for: part, barWidth: barWidth)
        // Use more efficient terminal update
        print("\r\u{1B}[K\(progressBar)", terminator: "")
        fflush(stdout)
    }
    
    private func createProgressBar(for part: DownloadPart, barWidth: Int) -> String {
        let speed = part.speedCalculator.calculateSpeed(bytes: part.completed)
        let eta = part.speedCalculator.estimateTimeRemaining(
            completed: part.completed,
            total: part.total
        )
        
        return ProgressBarFormatter.create(
            percentage: part.progress,
            width: barWidth,
            status: part.status,
            completed: part.completed,
            total: part.total,
            speed: speed,
            eta: eta,
            isCompleted: part.isComplete,
            digest: part.id.prefix(Constants.digestDisplayLength)
        )
    }
}

/// Cached terminal helper for better performance
class CachedTerminalHelper: TerminalHelper {
    private static var cachedWidth: Int?
    private static var lastCheck: Date?
    private static let cacheDuration: TimeInterval = 1.0
    
    var terminalWidth: Int {
        let now = Date()
        
        if let cached = Self.cachedWidth,
           let lastCheck = Self.lastCheck,
           now.timeIntervalSince(lastCheck) < Self.cacheDuration {
            return cached
        }
        
        let width = DefaultTerminalHelper().terminalWidth
        Self.cachedWidth = width
        Self.lastCheck = now
        return width
    }
    
    static func invalidateCache() {
        cachedWidth = nil
        lastCheck = nil
    }
}

/// Formatter for creating visual progress bars
struct ProgressBarFormatter {
    // MARK: - Constants
    
    private enum Constants {
        static let greenColor = "\u{1B}[32m"
        static let yellowColor = "\u{1B}[33m"
        static let cyanColor = "\u{1B}[36m"
        static let magentaColor = "\u{1B}[35m"
        static let resetColor = "\u{1B}[0m"
        
        static let filledChar = "█"
        static let emptyChar = "░"
        
        static let megabyteDivisor = 1_048_576.0
        static let etaRoundingInterval = 5
    }
    
    // MARK: - Public Interface
    
    static func create(
        percentage: Double,
        width: Int,
        status: String,
        completed: UInt64,
        total: UInt64,
        speed: Double,
        eta: Int,
        isCompleted: Bool,
        digest: Substring
    ) -> String {
        let (filled, empty) = createProgressSegments(percentage: percentage, width: width)
        let percentStr = String(format: "%6.2f%%", percentage)
        let sizeInfo = createSizeInfo(completed: completed, total: total)
        let additionalInfo = createAdditionalInfo(speed: speed, eta: eta, isCompleted: isCompleted)
        
        return "[\(filled)\(empty)] \(Constants.cyanColor)\(percentStr)\(Constants.resetColor) \(sizeInfo) \(additionalInfo) [\(digest)]"
    }
    
    // MARK: - Private Helpers
    
    private static func createProgressSegments(percentage: Double, width: Int) -> (String, String) {
        let filledWidth = Int(Double(width) * percentage / 100.0)
        let emptyWidth = width - filledWidth
        
        let filled = Constants.greenColor + String(repeating: Constants.filledChar, count: filledWidth) + Constants.resetColor
        let empty = String(repeating: Constants.emptyChar, count: emptyWidth)
        
        return (filled, empty)
    }
    
    private static func createSizeInfo(completed: UInt64, total: UInt64) -> String {
        "[\(FileSize.format(bytes: Int(completed)))/\(FileSize.format(bytes: Int(total)))]"
    }
    
    private static func createAdditionalInfo(speed: Double, eta: Int, isCompleted: Bool) -> String {
        if isCompleted {
            return "✓ Complete"
        } else if speed > 0.1 {
            return "\(Constants.yellowColor)\(formatSpeed(bytesPerSecond: speed))\(Constants.resetColor) \(Constants.magentaColor)\(formatETA(seconds: eta))\(Constants.resetColor)"
        } else {
            return "initializing..."
        }
    }
    
    private static func formatSpeed(bytesPerSecond: Double) -> String {
        let mbps = bytesPerSecond / Constants.megabyteDivisor
        return String(format: "%.1f MB/s", mbps)
    }
    
    private static func formatETA(seconds: Int) -> String {
        if seconds == 0 { return "calculating..." }
        
        let roundedSeconds = ((seconds + Constants.etaRoundingInterval - 1) / Constants.etaRoundingInterval) * Constants.etaRoundingInterval
        let hours = roundedSeconds / 3600
        let minutes = (roundedSeconds % 3600) / 60
        let remainingSeconds = roundedSeconds % 60
        
        if hours > 0 {
            return String(format: "ETA: %dh%02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "ETA: %dm%02ds", minutes, remainingSeconds)
        } else {
            return String(format: "ETA: %ds", remainingSeconds)
        }
    }
}