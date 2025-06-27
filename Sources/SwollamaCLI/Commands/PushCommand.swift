import Foundation
import Swollama

/// Command to push a model to the Ollama library
struct PushCommand: CommandProtocol {
    private let client: OllamaProtocol
    private let progressTracker: ProgressTracker
    
    init(client: OllamaProtocol, progressTracker: ProgressTracker) {
        self.client = client
        self.progressTracker = progressTracker
    }
    
    func execute(with arguments: [String]) async throws {
        guard arguments.count >= 1 else {
            throw CLIError.missingArgument("model name")
        }
        
        let modelNameString = arguments[0]
        guard let modelName = OllamaModelName.parse(modelNameString) else {
            throw CLIError.invalidArgument("Invalid model name format. Must include namespace (e.g., username/modelname:tag)")
        }
        
        // Check if model has namespace
        guard modelName.namespace != nil else {
            throw CLIError.invalidArgument("Model name must include namespace for pushing (e.g., username/modelname:tag)")
        }
        
        // Parse options
        var allowInsecure = false
        
        var i = 1
        while i < arguments.count {
            switch arguments[i] {
            case "--insecure":
                allowInsecure = true
                
            case "--help", "-h":
                printPushHelp()
                return
                
            default:
                throw CLIError.invalidArgument("Unknown option: \(arguments[i])")
            }
            i += 1
        }
        
        let options = PushOptions(allowInsecure: allowInsecure)
        
        print("Pushing model '\(modelName.fullName)' to Ollama library...")
        if allowInsecure {
            print("⚠️  Using insecure connection")
        }
        print("")
        
        do {
            let progressStream = try await client.pushModel(name: modelName, options: options)
            
            try await progressTracker.track(progressStream)
            
            print("\n✅ Model pushed successfully!")
        } catch {
            print("❌ Failed to push model: \(error)")
            throw error
        }
    }
    
    private func printPushHelp() {
        print("""
        Usage: swollama push <namespace/model:tag> [options]
        
        Push a model to the Ollama library. Requires registering for ollama.ai 
        and adding a public key first.
        
        Options:
            --insecure      Allow insecure connections (only for development)
            --help, -h      Show this help message
        
        Examples:
            # Push a model to your namespace
            swollama push myusername/llama3-custom:latest
            
            # Push with insecure connection (development only)
            swollama push myusername/test-model:v1 --insecure
        
        Note: The model name must include a namespace (username) when pushing.
        """)
    }
}