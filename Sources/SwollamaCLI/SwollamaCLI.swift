import Foundation
import Swollama

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@main
struct SwollamaCLI {
    static func main() async throws {

        #if os(Linux)
            LinuxSupport.installSignalHandlers()
            LinuxSupport.configureMemorySettings()
            LinuxSupport.configureProcessPriority()
        #endif

        var arguments = CommandLine.arguments

        arguments.removeFirst()

        if arguments.contains("--help") || arguments.contains("-h") || arguments.contains("help") {
            printUsage()
            return
        }

        if arguments.contains("--version") || arguments.contains("-v") {
            printVersion()
            return
        }

        if arguments.contains("--system-info") {
            printSystemInfo()
            return
        }

        let baseURL: URL
        if let hostIndex = arguments.firstIndex(of: "--host"),
            hostIndex + 1 < arguments.count
        {
            guard let url = normalizeHostURL(arguments[hostIndex + 1]) else {
                printToStderr("Error: Invalid URL '\(arguments[hostIndex + 1])'")
                exit(1)
            }
            baseURL = url

            arguments.removeSubrange(hostIndex...hostIndex + 1)
        } else if let envHost = ProcessInfo.processInfo.environment["OLLAMA_HOST"],
            !envHost.isEmpty
        {
            guard let url = normalizeHostURL(envHost) else {
                printToStderr("Error: Invalid OLLAMA_HOST '\(envHost)'")
                exit(1)
            }
            baseURL = url
        } else {

            baseURL = URL(string: "http://localhost:11434")!
        }

        guard !arguments.isEmpty else {
            printUsage()
            return
        }

        let command = arguments[0]
        let remainingArgs = Array(arguments.dropFirst())

        let apiKey = ProcessInfo.processInfo.environment["OLLAMA_API_KEY"]
        let client = OllamaClient(
            baseURL: baseURL,
            configuration: OllamaConfiguration(apiKey: apiKey?.isEmpty == false ? apiKey : nil)
        )

        do {
            switch command.lowercased() {
            case "list":
                try await ListModelsCommand(client: client).execute(with: remainingArgs)
            case "show":
                try await ShowModelCommand(client: client).execute(with: remainingArgs)
            case "pull":
                try await PullModelCommand(client: client).execute(with: remainingArgs)
            case "push":
                let progressTracker = DefaultProgressTracker()
                try await PushCommand(client: client, progressTracker: progressTracker).execute(
                    with: remainingArgs
                )
            case "create":
                let progressTracker = DefaultProgressTracker()
                try await CreateCommand(client: client, progressTracker: progressTracker).execute(
                    with: remainingArgs
                )
            case "copy":
                try await CopyModelCommand(client: client).execute(with: remainingArgs)
            case "delete":
                try await DeleteModelCommand(client: client).execute(with: remainingArgs)
            case "chat":
                try await EnhancedChatCommand(client: client).execute(with: remainingArgs)
            case "agent":
                try await AgentCommand().execute(with: remainingArgs)
            case "generate":
                try await GenerateCommand(client: client).execute(with: remainingArgs)
            case "embeddings", "embed":
                try await EmbeddingsCommand(client: client).execute(with: remainingArgs)
            case "ps":
                try await ListRunningModelsCommand(client: client).execute(with: remainingArgs)
            case "version":
                try await VersionCommand(client: client).execute(with: remainingArgs)
            case "blob":
                try await BlobCommand(client: client).execute(with: remainingArgs)
            case "test":
                try await TestCommand(client: client).execute(with: remainingArgs)
            case "help":
                printUsage()
            default:
                print("Error: Invalid command: \(command)")
                printUsage()
                exit(1)
            }
        } catch let error as CLIError {
            print("Error: \(error.errorDescription ?? "Unknown error")")
            exit(1)
        } catch {
            print("Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func printUsage() {
        print(
            """
            Usage: swollama [options] <command> [arguments]

            Options:
              --host <url>            Ollama API host (default: http://localhost:11434)
              --version, -v           Show version information
              --system-info           Display system information (Linux)
              --help, -h              Show this help message

            Commands:
              list                     List available models (with capabilities)
              show <model> [-v]        Show model info (--verbose for model_info + tensors)
              pull <model>            Download a model
              push <model>            Upload a model to Ollama library
              create <model>          Create a new model
              copy <src> <dst>        Create a copy of a model
              delete <model>          Remove a model
              chat <model>            Start a chat session (--think, --format json)
              agent <query>           Run an agentic workflow with web search
              generate <model>        Generate text (--prompt for one-shot, --think)
              embeddings <text>       Generate embeddings (--dimensions, --legacy)
              ps                      List running models
              version                 Show Ollama server version
              blob <subcommand>       Manage blobs (check/push)
              test [type]             Test new API features
              help                    Show this help message

            Environment:
              OLLAMA_HOST             Default host (e.g. 127.0.0.1:11434); --host overrides it
              OLLAMA_API_KEY          Bearer token sent with every request (auth'd/cloud hosts)
              NO_COLOR                Disable ANSI colors

            Examples:
              swollama list
              swollama --host http://remote:11434 list
              swollama show qwen3 --verbose
              swollama chat qwen3 --think
              swollama chat qwen3 "Summarize the plot of Dune in one line"
              swollama agent "what is ollama's new engine"
              swollama generate codellama --prompt "def fib(n):" --think
              swollama pull llama3.2
              swollama create mario --from llama3.2 --system "You are Mario"
              swollama embeddings "Hello world" --dimensions 256
              swollama test structured
              swollama version

            Linux Users:
              - Use --system-info for diagnostics
            """
        )
    }

    static let version = "4.2.0"

    static func printVersion() {
        print(
            """
            Swollama \(version)
            Platform: \(getPlatformName())
            Swift: 5.9+
            """
        )
    }

    static func printSystemInfo() {
        print(
            """
            Swollama System Information
            ==========================

            \(LinuxSupport.getSystemInfo())

            Performance Settings:
            - Network buffer size: 64KB
            - Terminal update rate: 10 FPS
            - Progress update threshold: 0.1%
            - Connection pooling: Enabled
            - Memory optimization: Active
            """
        )
    }

    /// Normalizes an Ollama host string (with or without a scheme) into a URL.
    ///
    /// Accepts `http://host:port`, `host:port`, `host`, or `:port` (localhost is assumed when the
    /// host is omitted), matching the flexibility of Ollama's own `OLLAMA_HOST`.
    static func normalizeHostURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains("://") {
            return URL(string: trimmed)
        }
        if trimmed.hasPrefix(":") {
            return URL(string: "http://localhost\(trimmed)")
        }
        return URL(string: "http://\(trimmed)")
    }

    static func getPlatformName() -> String {
        #if os(Linux)
            return "Linux"
        #elseif os(macOS)
            return "macOS"
        #elseif os(iOS)
            return "iOS"
        #else
            return "Unknown"
        #endif
    }
}
