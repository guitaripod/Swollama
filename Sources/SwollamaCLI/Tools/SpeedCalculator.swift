import Foundation

protocol SpeedCalculator {
    func calculateSpeed(bytes: UInt64) -> Double
    func estimateTimeRemaining(completed: UInt64, total: UInt64) -> Int
}

final class MovingAverageSpeedCalculator: SpeedCalculator {
    private var speedReadings: [(timestamp: Date, bytes: UInt64)] = []
    private let speedWindowSeconds: TimeInterval = 3.0

    func calculateSpeed(bytes: UInt64) -> Double {
        let now = Date()
        speedReadings.append((now, bytes))
        speedReadings = speedReadings.filter {
            now.timeIntervalSince($0.timestamp) <= speedWindowSeconds
        }

        guard speedReadings.count >= 2,
            let oldest = speedReadings.first
        else { return 0.0 }

        let timeSpan = now.timeIntervalSince(oldest.timestamp)
        let byteSpan = Double(bytes - oldest.bytes)
        return timeSpan > 0 ? byteSpan / timeSpan : 0
    }

    func estimateTimeRemaining(completed: UInt64, total: UInt64) -> Int {
        let speed = calculateSpeed(bytes: completed)
        let remainingBytes = Double(total - completed)
        return speed > 0 ? Int(remainingBytes / speed) : 0
    }
}
