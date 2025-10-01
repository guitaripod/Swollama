import Foundation
import Swollama

struct EnhancedSwollamaCLI {
    static let version = "2.0.0"
    static let defaultHost = "http://localhost:11434"

    enum CLIError: LocalizedError {
        case missingCommand
        case unknownCommand(String)
        case missingArgument(String)
        case invalidArgument(String)
        case connectionFailed(String)
        case configurationError(String)

        var errorDescription: String? {
            switch self {
            case .missingCommand:
                return "No command specified. Use 'swollama --help' for usage information."
            case .unknownCommand(let cmd):
                return "Unknown command: '\(cmd)'. Use 'swollama --help' for available commands."
            case .missingArgument(let arg):
                return "Missing required argument: \(arg)"
            case .invalidArgument(let arg):
                return "Invalid argument: \(arg)"
            case .connectionFailed(let reason):
                return "Failed to connect to Ollama: \(reason)"
            case .configurationError(let reason):
                return "Configuration error: \(reason)"
            }
        }
    }

    struct Configuration {
        let host: String
        let timeout: TimeInterval
        let retryAttempts: Int
        let verbose: Bool

        static func load(from arguments: [String]) -> Configuration {
            var host = ProcessInfo.processInfo.environment["OLLAMA_HOST"] ?? defaultHost
            var timeout: TimeInterval = 120
            var retryAttempts = 3
            var verbose = false

            var i = 0
            while i < arguments.count {
                switch arguments[i] {
                case "--host", "-h":
                    if i + 1 < arguments.count {
                        host = arguments[i + 1]
                        i += 1
                    }
                case "--timeout", "-t":
                    if i + 1 < arguments.count, let value = TimeInterval(arguments[i + 1]) {
                        timeout = value
                        i += 1
                    }
                case "--retry", "-r":
                    if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                        retryAttempts = value
                        i += 1
                    }
                case "--verbose", "-v":
                    verbose = true
                default:
                    break
                }
                i += 1
            }

            return Configuration(
                host: host,
                timeout: timeout,
                retryAttempts: retryAttempts,
                verbose: verbose
            )
        }
    }

    static func createCommand(_ name: String, client: OllamaProtocol) -> CommandProtocol? {
        switch name.lowercased() {
        case "chat", "c":
            return EnhancedChatCommand(client: client)
        case "list", "ls", "l":
            return ListModelsCommand(client: client)
        case "pull", "p":
            return PullModelCommand(client: client)
        case "push":
            return PushCommand(client: client, progressTracker: DefaultProgressTracker())
        case "delete", "rm", "remove", "d":
            return DeleteModelCommand(client: client)
        case "copy", "cp":
            return CopyModelCommand(client: client)
        case "show", "info", "i":
            return ShowModelCommand(client: client)
        case "blob", "blobs", "b":
            return BlobCommand(client: client)
        case "test", "t":
            return TestCommand(client: client)
        case "stream-test":
            return StreamTestCommand(client: client)
        default:
            return nil
        }
    }

    static func printHelp() {
        print(
            """
            \(EnhancedTerminalStyle.neonBlue)Swollama CLI v\(version)\(EnhancedTerminalStyle.reset)
            A powerful command-line interface for Ollama

            \(EnhancedTerminalStyle.neonGreen)USAGE:\(EnhancedTerminalStyle.reset)
                swollama [OPTIONS] <COMMAND> [ARGS]

            \(EnhancedTerminalStyle.neonGreen)COMMANDS:\(EnhancedTerminalStyle.reset)
                \(EnhancedTerminalStyle.neonYellow)chat, c\(EnhancedTerminalStyle.reset)      <model>    Start an interactive chat session
                \(EnhancedTerminalStyle.neonYellow)list, ls, l\(EnhancedTerminalStyle.reset)              List available models
                \(EnhancedTerminalStyle.neonYellow)pull, p\(EnhancedTerminalStyle.reset)      <model>    Download a model
                \(EnhancedTerminalStyle.neonYellow)push\(EnhancedTerminalStyle.reset)         <model>    Upload a model to registry
                \(EnhancedTerminalStyle.neonYellow)delete, rm\(EnhancedTerminalStyle.reset)   <model>    Delete a model
                \(EnhancedTerminalStyle.neonYellow)copy, cp\(EnhancedTerminalStyle.reset)     <src> <dst> Copy a model
                \(EnhancedTerminalStyle.neonYellow)show, info\(EnhancedTerminalStyle.reset)   <model>    Show model information
                \(EnhancedTerminalStyle.neonYellow)blob, b\(EnhancedTerminalStyle.reset)      <command>  Manage blobs
                \(EnhancedTerminalStyle.neonYellow)test, t\(EnhancedTerminalStyle.reset)                 Run tests

            \(EnhancedTerminalStyle.neonGreen)GLOBAL OPTIONS:\(EnhancedTerminalStyle.reset)
                \(EnhancedTerminalStyle.neonYellow)--host, -h\(EnhancedTerminalStyle.reset)   <url>      Ollama host (default: \(defaultHost))
                \(EnhancedTerminalStyle.neonYellow)--timeout, -t\(EnhancedTerminalStyle.reset) <seconds>  Request timeout (default: 120)
                \(EnhancedTerminalStyle.neonYellow)--retry, -r\(EnhancedTerminalStyle.reset)  <count>    Retry attempts (default: 3)
                \(EnhancedTerminalStyle.neonYellow)--verbose, -v\(EnhancedTerminalStyle.reset)            Enable verbose output
                \(EnhancedTerminalStyle.neonYellow)--help\(EnhancedTerminalStyle.reset)                   Show this help
                \(EnhancedTerminalStyle.neonYellow)--version\(EnhancedTerminalStyle.reset)                Show version

            \(EnhancedTerminalStyle.neonGreen)ENVIRONMENT:\(EnhancedTerminalStyle.reset)
                OLLAMA_HOST              Set default Ollama host

            \(EnhancedTerminalStyle.neonGreen)EXAMPLES:\(EnhancedTerminalStyle.reset)
                swollama chat llama2
                swollama chat codellama --no-timestamps
                swollama list
                swollama pull mistral
                swollama --host http://remote:11434 chat

            \(EnhancedTerminalStyle.neonGreen)CHAT COMMANDS:\(EnhancedTerminalStyle.reset)
                /help         Show available commands
                /exit         End conversation
                /save [file]  Save conversation
                /load [file]  Load conversation
                /retry        Retry last message
                /model <name> Switch model

            For more information, visit: https:
            """
        )
    }

    static func printVersion() {
        print("Swollama CLI v\(version)")
        print("Built with Swift and ❤️")
    }

    static func testConnection(client: OllamaClient) async -> Bool {
        do {
            _ = try await client.listModels()
            return true
        } catch {
            return false
        }
    }

    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if arguments.isEmpty || arguments.contains("--help") || arguments.contains("-h") {
            printHelp()
            return
        }

        if arguments.contains("--version") || arguments.contains("-v") {
            printVersion()
            return
        }

        let config = Configuration.load(from: arguments)

        let ollamaConfig = OllamaConfiguration(
            timeoutInterval: config.timeout,
            maxRetries: config.retryAttempts,
            retryDelay: 1.0
        )

        let client = OllamaClient(baseURL: URL(string: config.host)!, configuration: ollamaConfig)

        var commandName: String?
        var commandArgs: [String] = []
        var foundCommand = false

        for arg in arguments {
            if !foundCommand && !arg.starts(with: "-") {
                commandName = arg
                foundCommand = true
            } else if foundCommand && !arg.starts(with: "-") {
                commandArgs.append(arg)
            }
        }

        guard let commandName = commandName else {
            print(
                "\(EnhancedTerminalStyle.red)Error: No command specified\(EnhancedTerminalStyle.reset)"
            )
            print("Use 'swollama --help' for usage information")
            exit(1)
        }

        if config.verbose {
            print(
                "\(EnhancedTerminalStyle.dim)Connecting to Ollama at \(config.host)...\(EnhancedTerminalStyle.reset)"
            )
        }

        let isConnected = await testConnection(client: client)
        if !isConnected {
            print(
                "\(EnhancedTerminalStyle.red)Error: Cannot connect to Ollama at \(config.host)\(EnhancedTerminalStyle.reset)"
            )
            print("\(EnhancedTerminalStyle.neonYellow)Tips:\(EnhancedTerminalStyle.reset)")
            print(
                "  • Make sure Ollama is running: \(EnhancedTerminalStyle.neonGreen)ollama serve\(EnhancedTerminalStyle.reset)"
            )
            print(
                "  • Check if the host is correct: \(EnhancedTerminalStyle.gray)\(config.host)\(EnhancedTerminalStyle.reset)"
            )
            print("  • Try setting OLLAMA_HOST environment variable")
            exit(1)
        }

        guard let command = createCommand(commandName, client: client) else {
            print(
                "\(EnhancedTerminalStyle.red)Error: Unknown command '\(commandName)'\(EnhancedTerminalStyle.reset)"
            )
            print("Use 'swollama --help' for available commands")
            exit(1)
        }

        do {

            setupSignalHandlers()

            try await command.execute(with: commandArgs)

            cleanup()
        } catch let error as CLIError {
            print(
                "\(EnhancedTerminalStyle.red)Error: \(error.localizedDescription)\(EnhancedTerminalStyle.reset)"
            )
            exit(1)
        } catch {
            print(
                "\(EnhancedTerminalStyle.red)Unexpected error: \(error.localizedDescription)\(EnhancedTerminalStyle.reset)"
            )
            if config.verbose {
                print("\(EnhancedTerminalStyle.dim)Stack trace:\(EnhancedTerminalStyle.reset)")
                dump(error)
            }
            exit(1)
        }
    }

    static func setupSignalHandlers() {
        #if os(Linux)

            signal(SIGPIPE, SIG_IGN)

        #endif
    }

    static func cleanup() {

        print(EnhancedTerminalStyle.reset, terminator: "")

        print("\u{001B}[?25h", terminator: "")

        fflush(stdout)
    }
}
