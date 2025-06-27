#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation
import Swollama

@main
struct SwollamaCLI {
    static func main() async throws {
        // Initialize Linux-specific optimizations
        #if os(Linux)
        LinuxSupport.installSignalHandlers()
        LinuxSupport.configureMemorySettings()
        LinuxSupport.configureProcessPriority()
        #endif
        
        // Get command line arguments
        var arguments = CommandLine.arguments
        // Remove the executable name
        arguments.removeFirst()

        // Check for help flags before other parsing
        if arguments.contains("--help") || arguments.contains("-h") || arguments.contains("help") {
            printUsage()
            return
        }
        
        // Check for version flag
        if arguments.contains("--version") || arguments.contains("-v") {
            printVersion()
            return
        }
        
        // Check for system info flag (Linux diagnostic feature)
        if arguments.contains("--system-info") {
            printSystemInfo()
            return
        }

        // Parse host option first
        let baseURL: URL
        if let hostIndex = arguments.firstIndex(of: "--host"),
           hostIndex + 1 < arguments.count {
            baseURL = URL(string: arguments[hostIndex + 1])!
            // Remove the --host and its value from arguments
            arguments.removeSubrange(hostIndex...hostIndex+1)
        } else {
            baseURL = URL(string: "http://localhost:11434")!
        }

        guard !arguments.isEmpty else {
            printUsage()
            return
        }

        let command = arguments[0]
        let remainingArgs = Array(arguments.dropFirst())
        let client = OllamaClient(baseURL: baseURL)

        do {
            switch command.lowercased() {
            case "list":
                try await ListModelsCommand(client: client).execute(with: remainingArgs)
            case "show":
                try await ShowModelCommand(client: client).execute(with: remainingArgs)
            case "pull":
                try await PullModelCommand(client: client).execute(with: remainingArgs)
            case "copy":
                try await CopyModelCommand(client: client).execute(with: remainingArgs)
            case "delete":
                try await DeleteModelCommand(client: client).execute(with: remainingArgs)
            case "chat":
                try await ChatCommand(client: client).execute(with: remainingArgs)
            case "generate":
                try await GenerateCommand(client: client).execute(with: remainingArgs)
            case "ps":
                try await ListRunningModelsCommand(client: client).execute(with: remainingArgs)
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
        print("""
        Usage: swollama [options] <command> [arguments]
        
        Options:
          --host <url>            Ollama API host (default: http://localhost:11434)
          --version, -v           Show version information
          --system-info           Display system information (Linux)
          --help, -h              Show this help message
        
        Commands:
          list                     List available models
          show <model>            Show model information
          pull <model>            Download a model
          copy <src> <dst>        Create a copy of a model
          delete <model>          Remove a model
          chat [model]            Start a chat session
          generate [model]        Generate text from a prompt
          ps                      List running models
          help                    Show this help message
        
        Examples:
          swollama list
          swollama --host http://remote:11434 list
          swollama chat llama2
          swollama generate codellama
          swollama pull llama2
        
        Linux Users:
          - See linux/README.md for deployment guide
          - Use --system-info for diagnostics
        """)
    }
    
    static func printVersion() {
        print("""
        Swollama v1.0.0
        Platform: \(getPlatformName())
        Swift: 5.9+
        """)
    }
    
    static func printSystemInfo() {
        print("""
        Swollama System Information
        ==========================
        
        \(LinuxSupport.getSystemInfo())
        
        Performance Settings:
        - Network buffer size: 64KB
        - Terminal update rate: 10 FPS
        - Progress update threshold: 0.1%
        - Connection pooling: Enabled
        - Memory optimization: Active
        """)
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
