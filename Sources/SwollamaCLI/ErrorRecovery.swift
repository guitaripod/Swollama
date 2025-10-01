import Foundation
import Swollama


enum RecoveryStrategy {
    case retry(attempts: Int, delay: TimeInterval)
    case fallback(model: OllamaModelName)
    case skip
    case abort
    case reconnect
    case switchHost(String)
}


class ErrorRecoveryHandler {
    private let client: OllamaProtocol
    private var errorHistory: [(Date, Error)] = []
    private let maxHistorySize = 50

    init(client: OllamaProtocol) {
        self.client = client
    }


    func suggestRecovery(for error: Error) -> RecoveryStrategy {

        errorHistory.append((Date(), error))
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst()
        }


        if let ollamaError = error as? OllamaError {
            switch ollamaError {
            case .networkError:

                let recentNetworkErrors = countRecentNetworkErrors(within: 60)
                if recentNetworkErrors > 3 {
                    return .reconnect
                } else {
                    return .retry(attempts: 3, delay: 2.0)
                }

            case .modelNotFound:

                return .fallback(model: OllamaModelName(namespace: nil, name: "llama2", tag: "latest"))

            case .serverError:
                return .retry(attempts: 2, delay: 5.0)

            case .unexpectedStatusCode(let code):
                if code == 503 {

                    return .retry(attempts: 5, delay: 10.0)
                } else if code >= 500 {
                    return .retry(attempts: 2, delay: 3.0)
                } else {
                    return .skip
                }

            case .cancelled:
                return .skip

            default:
                return .skip
            }
        }


        return .retry(attempts: 1, delay: 1.0)
    }


    func executeRecovery(
        strategy: RecoveryStrategy,
        operation: @escaping () async throws -> Void
    ) async throws {
        switch strategy {
        case .retry(let attempts, let delay):
            for attempt in 1...attempts {
                do {
                    try await operation()
                    return
                } catch {
                    if attempt < attempts {
                        print("\n\(EnhancedTerminalStyle.orange)Retry attempt \(attempt)/\(attempts) in \(Int(delay))s...\(EnhancedTerminalStyle.reset)")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } else {
                        throw error
                    }
                }
            }

        case .fallback(let model):
            print("\n\(EnhancedTerminalStyle.orange)Switching to fallback model: \(model.fullName)\(EnhancedTerminalStyle.reset)")

            throw RecoveryError.fallbackRequired(model: model)

        case .skip:
            print("\n\(EnhancedTerminalStyle.orange)Skipping operation due to error\(EnhancedTerminalStyle.reset)")
            return

        case .abort:
            print("\n\(EnhancedTerminalStyle.red)Operation aborted\(EnhancedTerminalStyle.reset)")
            throw RecoveryError.aborted

        case .reconnect:
            print("\n\(EnhancedTerminalStyle.orange)Attempting to reconnect...\(EnhancedTerminalStyle.reset)")
            try await reconnect()
            try await operation()

        case .switchHost(let newHost):
            print("\n\(EnhancedTerminalStyle.orange)Switching to host: \(newHost)\(EnhancedTerminalStyle.reset)")
            throw RecoveryError.hostSwitchRequired(host: newHost)
        }
    }


    private func reconnect() async throws {
        guard let client = client as? OllamaClient else {
            throw RecoveryError.reconnectFailed
        }


        _ = try await client.listModels()
        print("\(EnhancedTerminalStyle.neonGreen)Reconnected successfully\(EnhancedTerminalStyle.reset)")
    }


    private func countRecentNetworkErrors(within seconds: TimeInterval) -> Int {
        let cutoffDate = Date().addingTimeInterval(-seconds)
        return errorHistory.filter { date, error in
            if let ollamaError = error as? OllamaError,
               case .networkError = ollamaError {
                return date > cutoffDate
            }
            return false
        }.count
    }


    func clearHistory() {
        errorHistory.removeAll()
    }
}


enum RecoveryError: LocalizedError {
    case fallbackRequired(model: OllamaModelName)
    case hostSwitchRequired(host: String)
    case reconnectFailed
    case aborted

    var errorDescription: String? {
        switch self {
        case .fallbackRequired(let model):
            return "Fallback to model '\(model.fullName)' required"
        case .hostSwitchRequired(let host):
            return "Switch to host '\(host)' required"
        case .reconnectFailed:
            return "Failed to reconnect to server"
        case .aborted:
            return "Operation aborted by recovery handler"
        }
    }
}


class ResilientChatSession {
    private let client: OllamaProtocol
    private let recoveryHandler: ErrorRecoveryHandler
    private var currentModel: OllamaModelName
    private var messages: [ChatMessage] = []
    private let inputHandler = InputHandler()

    init(client: OllamaProtocol, model: OllamaModelName) {
        self.client = client
        self.currentModel = model
        self.recoveryHandler = ErrorRecoveryHandler(client: client)
    }


    func sendMessage(_ content: String) async throws -> String {
        messages.append(ChatMessage(role: .user, content: content))

        var lastError: Error?
        var response = ""


        for _ in 0..<3 {
            do {
                response = try await generateResponse()
                messages.append(ChatMessage(role: .assistant, content: response))
                return response
            } catch {
                lastError = error


                let strategy = recoveryHandler.suggestRecovery(for: error)


                if case .fallback(let fallbackModel) = strategy {
                    currentModel = fallbackModel
                    continue
                }


                do {
                    try await recoveryHandler.executeRecovery(strategy: strategy) {
                        response = try await self.generateResponse()
                    }
                    messages.append(ChatMessage(role: .assistant, content: response))
                    return response
                } catch RecoveryError.fallbackRequired(let model) {
                    currentModel = model
                    continue
                } catch {

                    continue
                }
            }
        }


        throw lastError ?? RecoveryError.aborted
    }

    private func generateResponse() async throws -> String {
        guard let client = client as? OllamaClient else {
            throw CLIError.invalidArgument("Chat requires OllamaClient")
        }

        let stream = try await client.chat(
            messages: messages,
            model: currentModel,
            options: .default
        )

        var fullResponse = ""

        for try await response in stream {
            if !response.message.content.isEmpty {
                fullResponse += response.message.content
            }
        }

        return fullResponse
    }


    func promptForRecovery(error: Error) async -> RecoveryStrategy {
        print("\n\(EnhancedTerminalStyle.red)Error occurred: \(error.localizedDescription)\(EnhancedTerminalStyle.reset)")

        let options: [(String, RecoveryStrategy)] = [
            ("Retry with current settings", .retry(attempts: 1, delay: 0)),
            ("Retry with delay", .retry(attempts: 3, delay: 2.0)),
            ("Switch to llama2 model", .fallback(model: OllamaModelName(namespace: nil, name: "llama2", tag: "latest"))),
            ("Skip this message", .skip),
            ("Reconnect to server", .reconnect),
            ("Abort conversation", .abort)
        ]

        if let selection = inputHandler.selectOption(
            prompt: "\nHow would you like to proceed?",
            options: options
        ) {
            return selection
        }

        return .abort
    }
}


class HealthMonitor {
    private let client: OllamaProtocol
    private var isHealthy = true
    private var lastCheckTime: Date?
    private let checkInterval: TimeInterval = 30.0

    init(client: OllamaProtocol) {
        self.client = client
    }

    func startMonitoring() {
        Task {
            while true {
                await checkHealth()
                try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
            }
        }
    }

    private func checkHealth() async {
        guard let client = client as? OllamaClient else { return }

        do {
            _ = try await client.listModels()
            if !isHealthy {
                isHealthy = true
                print("\n\(EnhancedTerminalStyle.neonGreen)Connection restored\(EnhancedTerminalStyle.reset)")
            }
            lastCheckTime = Date()
        } catch {
            if isHealthy {
                isHealthy = false
                print("\n\(EnhancedTerminalStyle.red)Connection lost: \(error.localizedDescription)\(EnhancedTerminalStyle.reset)")
            }
        }
    }

    var status: String {
        if isHealthy {
            return "\(EnhancedTerminalStyle.neonGreen)● Healthy\(EnhancedTerminalStyle.reset)"
        } else {
            return "\(EnhancedTerminalStyle.red)● Unhealthy\(EnhancedTerminalStyle.reset)"
        }
    }
}