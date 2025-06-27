import Foundation
import Swollama

/// Command to create a new model
struct CreateCommand: CommandProtocol {
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
        
        let modelName = arguments[0]
        
        // Parse additional options
        var fromModel: String? = nil
        var systemPrompt: String? = nil
        var template: String? = nil
        var quantize: QuantizationType? = nil
        var parameters: ModelfileParameters? = nil
        
        var i = 1
        while i < arguments.count {
            switch arguments[i] {
            case "--from", "-f":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--from requires a model name")
                }
                fromModel = arguments[i]
                
            case "--system", "-s":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--system requires a prompt")
                }
                systemPrompt = arguments[i]
                
            case "--template", "-t":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--template requires a template string")
                }
                template = arguments[i]
                
            case "--quantize", "-q":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--quantize requires a type (q4_K_M, q4_K_S, q8_0)")
                }
                quantize = QuantizationType(rawValue: arguments[i])
                if quantize == nil {
                    throw CLIError.invalidArgument("Invalid quantization type. Valid options: q4_K_M, q4_K_S, q8_0")
                }
                
            case "--temperature":
                i += 1
                guard i < arguments.count else {
                    throw CLIError.missingArgument("--temperature requires a value")
                }
                guard let temp = Double(arguments[i]) else {
                    throw CLIError.invalidArgument("Invalid temperature value")
                }
                if parameters == nil {
                    parameters = ModelfileParameters()
                }
                parameters = ModelfileParameters(temperature: temp)
                
            case "--help", "-h":
                printCreateHelp()
                return
                
            default:
                throw CLIError.invalidArgument("Unknown option: \(arguments[i])")
            }
            i += 1
        }
        
        // Create the request
        let request = CreateModelRequest(
            model: modelName,
            from: fromModel,
            template: template,
            system: systemPrompt,
            parameters: parameters,
            quantize: quantize
        )
        
        print("Creating model '\(modelName)'...")
        if let fromModel = fromModel {
            print("Base model: \(fromModel)")
        }
        if let systemPrompt = systemPrompt {
            print("System prompt: \(systemPrompt)")
        }
        if let quantize = quantize {
            print("Quantization: \(quantize.rawValue)")
        }
        print("")
        
        do {
            let progressStream = try await client.createModel(request)
            
            try await progressTracker.track(progressStream)
            
            print("\n✅ Model '\(modelName)' created successfully!")
        } catch {
            print("❌ Failed to create model: \(error)")
            throw error
        }
    }
    
    private func printCreateHelp() {
        print("""
        Usage: swollama create <model-name> [options]
        
        Create a new model from an existing model, GGUF files, or Safetensors.
        
        Options:
            --from, -f <model>      Base model to create from
            --system, -s <prompt>   System prompt for the model
            --template, -t <tmpl>   Prompt template
            --quantize, -q <type>   Quantization type (q4_K_M, q4_K_S, q8_0)
            --temperature <value>   Temperature parameter
            --help, -h              Show this help message
        
        Examples:
            # Create a custom model from llama3.2
            swollama create mario --from llama3.2 --system "You are Mario from Super Mario Bros."
            
            # Create a quantized version
            swollama create llama3.2:quantized --from llama3.2:3b-instruct-fp16 --quantize q4_K_M
        """)
    }
}