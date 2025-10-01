import Foundation
import Swollama

struct ListRunningModelsCommand: CommandProtocol {
    private let client: OllamaProtocol

    init(client: OllamaProtocol) {
        self.client = client
    }

    func execute(with arguments: [String]) async throws {
        print("Fetching running models...")
        let models = try await client.listRunningModels()

        if models.isEmpty {
            print("\nNo models currently running.")
            return
        }

        print("\nRunning Models:")
        print("--------------")
        for model in models {
            print("- Model: \(model.name)")
            print("  Full ID: \(model.model)")
            print("  Size: \(formatBytes(model.size))")
            print("  VRAM Usage: \(formatBytes(model.sizeVRAM))")
            print("  Expires: \(formatDate(model.expiresAt))")
            print("  Details:")
            print("    Family: \(model.details.family)")
            print("    Parameter Size: \(model.details.parameterSize)")
            print("    Quantization: \(model.details.quantizationLevel)")
            print("    Format: \(model.details.format)")
            print("")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)

        let relativeTime: String
        if timeInterval > 0 {

            let minutes = Int(timeInterval / 60)
            let hours = minutes / 60
            let days = hours / 24

            if days > 0 {
                relativeTime = "in \(days) day\(days == 1 ? "" : "s")"
            } else if hours > 0 {
                relativeTime = "in \(hours) hour\(hours == 1 ? "" : "s")"
            } else if minutes > 0 {
                relativeTime = "in \(minutes) minute\(minutes == 1 ? "" : "s")"
            } else {
                relativeTime = "in less than a minute"
            }
        } else {

            let minutes = Int(-timeInterval / 60)
            let hours = minutes / 60
            let days = hours / 24

            if days > 0 {
                relativeTime = "\(days) day\(days == 1 ? "" : "s") ago"
            } else if hours > 0 {
                relativeTime = "\(hours) hour\(hours == 1 ? "" : "s") ago"
            } else if minutes > 0 {
                relativeTime = "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
            } else {
                relativeTime = "less than a minute ago"
            }
        }

        let absoluteFormatter = DateFormatter()
        absoluteFormatter.dateStyle = .medium
        absoluteFormatter.timeStyle = .medium
        let absoluteTime = absoluteFormatter.string(from: date)

        return "\(relativeTime) (\(absoluteTime))"
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        return String(format: "%.2f %@", value, units[unitIndex])
    }
}
