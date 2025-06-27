import Foundation
import Swollama

// Stream debugging utilities
struct StreamDebugger {
    static var isEnabled = false
    static var logFile: FileHandle?
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    static func configure(enabled: Bool, logPath: String? = nil) {
        isEnabled = enabled
        
        if enabled, let logPath = logPath {
            let url = URL(fileURLWithPath: logPath)
            FileManager.default.createFile(atPath: logPath, contents: nil)
            logFile = try? FileHandle(forWritingTo: url)
        }
    }
    
    static func log(_ message: String, type: LogType = .info) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(type.rawValue)] \(message)\n"
        
        // Console output with colors
        let coloredMessage = "\(type.color)[\(type.rawValue)]\(EnhancedTerminalStyle.reset) \(message)"
        print(coloredMessage)
        
        // File output
        if let logFile = logFile,
           let data = logMessage.data(using: .utf8) {
            logFile.write(data)
        }
    }
    
    enum LogType: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case debug = "DEBUG"
        case stream = "STREAM"
        
        var color: String {
            switch self {
            case .info: return EnhancedTerminalStyle.neonBlue
            case .warning: return EnhancedTerminalStyle.orange
            case .error: return EnhancedTerminalStyle.red
            case .debug: return EnhancedTerminalStyle.gray
            case .stream: return EnhancedTerminalStyle.neonGreen
            }
        }
    }
}

// Stream monitoring wrapper
class StreamMonitor<T> {
    private let stream: AsyncThrowingStream<T, Error>
    private let name: String
    private var chunkCount = 0
    private var byteCount = 0
    private let startTime = Date()
    
    init(stream: AsyncThrowingStream<T, Error>, name: String) {
        self.stream = stream
        self.name = name
        StreamDebugger.log("Stream '\(name)' initialized", type: .stream)
    }
    
    func makeAsyncIterator() -> AsyncThrowingStream<T, Error>.AsyncIterator {
        StreamDebugger.log("Stream '\(name)' iterator created", type: .debug)
        return stream.makeAsyncIterator()
    }
    
    func monitoredStream() -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await value in stream {
                        chunkCount += 1
                        
                        // Log chunk details
                        if let chatResponse = value as? ChatResponse {
                            byteCount += chatResponse.message.content.count
                            StreamDebugger.log(
                                "Chunk #\(chunkCount): '\(chatResponse.message.content)' (done: \(chatResponse.done))",
                                type: .stream
                            )
                        } else if let generateResponse = value as? GenerateResponse {
                            byteCount += generateResponse.response.count
                            StreamDebugger.log(
                                "Chunk #\(chunkCount): '\(generateResponse.response)' (done: \(generateResponse.done))",
                                type: .stream
                            )
                        }
                        
                        continuation.yield(value)
                    }
                    
                    let duration = Date().timeIntervalSince(startTime)
                    StreamDebugger.log(
                        "Stream '\(name)' completed: \(chunkCount) chunks, \(byteCount) bytes, \(String(format: "%.2f", duration))s",
                        type: .info
                    )
                    continuation.finish()
                } catch {
                    StreamDebugger.log(
                        "Stream '\(name)' error: \(error)",
                        type: .error
                    )
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// Network traffic monitor
class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private var requestCount = 0
    private var responseCount = 0
    private var totalBytesReceived = 0
    private var totalBytesSent = 0
    
    func logRequest(endpoint: String, method: String, bodySize: Int) {
        requestCount += 1
        totalBytesSent += bodySize
        StreamDebugger.log(
            "Request #\(requestCount): \(method) \(endpoint) (\(bodySize) bytes)",
            type: .debug
        )
    }
    
    func logResponse(statusCode: Int, bodySize: Int) {
        responseCount += 1
        totalBytesReceived += bodySize
        StreamDebugger.log(
            "Response #\(responseCount): Status \(statusCode) (\(bodySize) bytes)",
            type: .debug
        )
    }
    
    func printStatistics() {
        print("\n\(EnhancedTerminalStyle.neonBlue)Network Statistics:\(EnhancedTerminalStyle.reset)")
        print("  Requests sent: \(requestCount)")
        print("  Responses received: \(responseCount)")
        print("  Bytes sent: \(formatBytes(totalBytesSent))")
        print("  Bytes received: \(formatBytes(totalBytesReceived))")
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var size = Double(bytes)
        var unitIndex = 0
        
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", size, units[unitIndex])
    }
}

// Streaming test command
struct StreamTestCommand: CommandProtocol {
    private let client: OllamaProtocol
    
    init(client: OllamaProtocol) {
        self.client = client
    }
    
    func execute(with arguments: [String]) async throws {
        guard !arguments.isEmpty else {
            throw CLIError.missingArgument("Model name required")
        }
        
        guard let model = OllamaModelName.parse(arguments[0]) else {
            throw CLIError.invalidArgument("Invalid model name format")
        }
        
        // Enable debugging
        StreamDebugger.configure(enabled: true, logPath: "stream_debug.log")
        
        print("\(EnhancedTerminalStyle.neonBlue)Starting stream test with model: \(model.fullName)\(EnhancedTerminalStyle.reset)")
        
        guard let client = client as? OllamaClient else {
            throw CLIError.invalidArgument("Stream test requires OllamaClient")
        }
        
        // Test 1: Simple generation
        print("\n\(EnhancedTerminalStyle.neonGreen)Test 1: Simple generation\(EnhancedTerminalStyle.reset)")
        try await testGeneration(client: client, model: model)
        
        // Test 2: Chat streaming
        print("\n\(EnhancedTerminalStyle.neonGreen)Test 2: Chat streaming\(EnhancedTerminalStyle.reset)")
        try await testChat(client: client, model: model)
        
        // Test 3: Concurrent streams
        print("\n\(EnhancedTerminalStyle.neonGreen)Test 3: Concurrent streams\(EnhancedTerminalStyle.reset)")
        try await testConcurrentStreams(client: client, model: model)
        
        // Print statistics
        NetworkMonitor.shared.printStatistics()
    }
    
    private func testGeneration(client: OllamaClient, model: OllamaModelName) async throws {
        let prompt = "Count from 1 to 5 slowly"
        print("Prompt: \(prompt)")
        
        let stream = try await client.generateText(
            prompt: prompt,
            model: model,
            options: .default
        )
        
        let monitoredStream = StreamMonitor(stream: stream, name: "generation").monitoredStream()
        
        print("Response: ", terminator: "")
        for try await response in monitoredStream {
            print(response.response, terminator: "")
            fflush(stdout)
        }
        print()
    }
    
    private func testChat(client: OllamaClient, model: OllamaModelName) async throws {
        let messages = [
            ChatMessage(role: .user, content: "Say 'Hello World' one word at a time")
        ]
        
        print("Messages: \(messages[0].content)")
        
        let stream = try await client.chat(
            messages: messages,
            model: model,
            options: .default
        )
        
        let monitoredStream = StreamMonitor(stream: stream, name: "chat").monitoredStream()
        
        print("Response: ", terminator: "")
        for try await response in monitoredStream {
            print(response.message.content, terminator: "")
            fflush(stdout)
        }
        print()
    }
    
    private func testConcurrentStreams(client: OllamaClient, model: OllamaModelName) async throws {
        print("Starting 3 concurrent streams...")
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...3 {
                group.addTask {
                    do {
                        let messages = [
                            ChatMessage(role: .user, content: "Count to \(i)")
                        ]
                        
                        let stream = try await client.chat(
                            messages: messages,
                            model: model,
                            options: .default
                        )
                        
                        print("\nStream \(i): ", terminator: "")
                        for try await response in stream {
                            print(response.message.content, terminator: "")
                            fflush(stdout)
                        }
                    } catch {
                        print("\nStream \(i) error: \(error)")
                    }
                }
            }
        }
        print()
    }
}