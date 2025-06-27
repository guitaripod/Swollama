import Foundation

/// A protocol defining the core functionality of an Ollama client.
///
/// This protocol provides a comprehensive interface for interacting with the Ollama API,
/// supporting all endpoints documented at [Ollama API](https://github.com/ollama/ollama/blob/main/docs/api.md).
///
/// ## Overview
///
/// `OllamaProtocol` defines methods for:
/// - Model management (list, show, pull, push, copy, delete)
/// - Text generation with streaming support
/// - Chat completions with tool calling
/// - Embeddings generation
/// - Model creation from Modelfiles, GGUF, or Safetensors
/// - Blob management for large files
/// - Server information
///
/// ## Topics
///
/// ### Model Management
/// - ``listModels()``
/// - ``showModel(name:verbose:)``
/// - ``pullModel(name:options:)``
/// - ``pushModel(name:options:)``
/// - ``copyModel(source:destination:)``
/// - ``deleteModel(name:)``
/// - ``listRunningModels()``
///
/// ### Model Creation
/// - ``createModel(_:)``
/// - ``checkBlobExists(digest:)``
/// - ``pushBlob(digest:data:)``
///
/// ### Generation
/// - ``OllamaClient/generateText(prompt:model:options:)``
/// - ``OllamaClient/chat(messages:model:options:)``
/// - ``OllamaClient/generateEmbeddings(input:model:options:)``
///
/// ### Server Information
/// - ``getVersion()``
public protocol OllamaProtocol: Sendable {
    /// The base URL of the Ollama API server
    var baseURL: URL { get }

    /// The configuration used for API requests
    var configuration: OllamaConfiguration { get }

    /// Lists all models that are available locally.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let models = try await client.listModels()
    ///     for model in models.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }) {
    ///         print(model.name)
    ///     }
    /// } catch {
    ///     print("Error listing models: \(error)")
    /// }
    /// ```
    ///
    /// - Returns: An array of detailed model information.
    /// - Throws: An `OllamaError` if the request fails.
    func listModels() async throws -> [ModelListEntry]

    /// Shows detailed information about a specific model.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     guard let modelName = OllamaModelName.parse("llama2") else {
    ///         throw CLIError.invalidArgument("Invalid model name format")
    ///     }
    ///     let info = try await client.showModel(name: modelName)
    ///     print("Format: \(info.details.format)")
    ///     print("Family: \(info.details.family)")
    ///     print("Parameter Size: \(info.details.parameterSize)")
    ///     print("Quantization: \(info.details.quantizationLevel)")
    /// } catch {
    ///     print("Error showing model details: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the model to show information for.
    ///   - verbose: If true, returns full data for verbose response fields.
    /// - Returns: Detailed information about the model.
    /// - Throws: An `OllamaError` if the request fails.
    func showModel(name: OllamaModelName, verbose: Bool?) async throws -> ModelInformation

    /// Pulls a model from the Ollama library.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     guard let modelName = OllamaModelName.parse("llama2") else {
    ///         throw CLIError.invalidArgument("Invalid model name format")
    ///     }
    ///     let progress = try await client.pullModel(
    ///         name: modelName,
    ///         options: PullOptions()
    ///     )
    ///     for try await update in progress {
    ///         print("Status: \(update.status)")
    ///     }
    /// } catch {
    ///     print("Error pulling model: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the model to pull.
    ///   - options: Optional parameters for the pull operation.
    /// - Returns: An async sequence of progress updates.
    /// - Throws: An `OllamaError` if the request fails.
    func pullModel(
        name: OllamaModelName,
        options: PullOptions
    ) async throws -> AsyncThrowingStream<OperationProgress, Error>

    /// Pushes a model to the Ollama library.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     guard let modelName = OllamaModelName.parse("my-custom-model") else {
    ///         throw CLIError.invalidArgument("Invalid model name format")
    ///     }
    ///     let progress = try await client.pushModel(
    ///         name: modelName,
    ///         options: PushOptions()
    ///     )
    ///     for try await update in progress {
    ///         print("Status: \(update.status)")
    ///     }
    /// } catch {
    ///     print("Error pushing model: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the model to push.
    ///   - options: Optional parameters for the push operation.
    /// - Returns: An async sequence of progress updates.
    /// - Throws: An `OllamaError` if the request fails.
    func pushModel(
        name: OllamaModelName,
        options: PushOptions
    ) async throws -> AsyncThrowingStream<OperationProgress, Error>

    /// Copies a model.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     guard let sourceModel = OllamaModelName.parse("llama2"),
    ///           let destModel = OllamaModelName.parse("llama2-custom") else {
    ///         throw CLIError.invalidArgument("Invalid model name format")
    ///     }
    ///     try await client.copyModel(source: sourceModel, destination: destModel)
    ///     print("Model copied successfully")
    /// } catch {
    ///     print("Error copying model: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - source: The source model name.
    ///   - destination: The destination model name.
    /// - Throws: An `OllamaError` if the request fails.
    func copyModel(source: OllamaModelName, destination: OllamaModelName) async throws

    /// Deletes a model.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     guard let modelName = OllamaModelName.parse("unused-model") else {
    ///         throw CLIError.invalidArgument("Invalid model name format")
    ///     }
    ///     try await client.deleteModel(name: modelName)
    ///     print("Model deleted successfully")
    /// } catch {
    ///     print("Error deleting model: \(error)")
    /// }
    /// ```
    ///
    /// - Parameter name: The name of the model to delete.
    /// - Throws: An `OllamaError` if the request fails.
    func deleteModel(name: OllamaModelName) async throws

    /// Lists currently running models.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let runningModels = try await client.listRunningModels()
    ///     for model in runningModels {
    ///         print("Model: \(model.name)")
    ///         print("VRAM Usage: \(model.sizeVRAM) bytes")
    ///         print("Expires: \(model.expiresAt)")
    ///         print("Details:")
    ///         print("  Family: \(model.details.family)")
    ///         print("  Parameter Size: \(model.details.parameterSize)")
    ///         print("  Quantization: \(model.details.quantizationLevel)")
    ///     }
    /// } catch {
    ///     print("Error listing running models: \(error)")
    /// }
    /// ```
    ///
    /// - Returns: An array of running model information.
    /// - Throws: An `OllamaError` if the request fails.
    func listRunningModels() async throws -> [RunningModelInfo]
    
    /// Creates a new model from another model, GGUF files, or Safetensors.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let request = CreateModelRequest(
    ///         model: "mario",
    ///         from: "llama3.2",
    ///         system: "You are Mario from Super Mario Bros."
    ///     )
    ///     let progress = try await client.createModel(request)
    ///     for try await update in progress {
    ///         print("Status: \(update.status)")
    ///     }
    /// } catch {
    ///     print("Error creating model: \(error)")
    /// }
    /// ```
    ///
    /// - Parameter request: The model creation parameters.
    /// - Returns: An async sequence of progress updates.
    /// - Throws: An `OllamaError` if the request fails.
    func createModel(_ request: CreateModelRequest) async throws -> AsyncThrowingStream<OperationProgress, Error>
    
    /// Checks if a blob exists on the server.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let exists = try await client.checkBlobExists(digest: "sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2")
    ///     print("Blob exists: \(exists)")
    /// } catch {
    ///     print("Error checking blob: \(error)")
    /// }
    /// ```
    ///
    /// - Parameter digest: The SHA256 digest of the blob.
    /// - Returns: True if the blob exists, false otherwise.
    /// - Throws: An `OllamaError` if the request fails.
    func checkBlobExists(digest: String) async throws -> Bool
    
    /// Pushes a blob to the server.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let fileData = try Data(contentsOf: URL(fileURLWithPath: "model.gguf"))
    ///     try await client.pushBlob(digest: "sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2", data: fileData)
    ///     print("Blob pushed successfully")
    /// } catch {
    ///     print("Error pushing blob: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - digest: The expected SHA256 digest of the blob.
    ///   - data: The blob data to push.
    /// - Throws: An `OllamaError` if the request fails.
    func pushBlob(digest: String, data: Data) async throws
    
    /// Gets the Ollama server version.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let version = try await client.getVersion()
    ///     print("Ollama version: \(version.version)")
    /// } catch {
    ///     print("Error getting version: \(error)")
    /// }
    /// ```
    ///
    /// - Returns: The server version information.
    /// - Throws: An `OllamaError` if the request fails.
    func getVersion() async throws -> VersionResponse
}
