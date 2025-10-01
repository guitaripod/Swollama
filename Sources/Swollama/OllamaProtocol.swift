import Foundation








































/// Protocol defining the complete Ollama API interface.
///
/// `OllamaProtocol` defines all available operations for interacting with an Ollama server,
/// including text generation, chat completions, embeddings, and model management. Types
/// conforming to this protocol provide a complete client implementation for the Ollama API.
///
/// The primary conforming type is ``OllamaClient``, which provides a thread-safe actor-based
/// implementation.
///
/// ## Operations
///
/// The protocol includes methods for:
/// - **Generation**: ``generateText(prompt:model:options:)`` and ``chat(messages:model:options:)``
/// - **Embeddings**: ``generateEmbeddings(input:model:options:)``
/// - **Model Management**: ``listModels()``, ``showModel(name:verbose:)``, ``pullModel(name:options:)``, ``pushModel(name:options:)``, ``copyModel(source:destination:)``, ``deleteModel(name:)``
/// - **Running Models**: ``listRunningModels()``
/// - **Model Creation**: ``createModel(_:)``
/// - **Blob Management**: ``checkBlobExists(digest:)``, ``pushBlob(digest:data:)``
/// - **Server Info**: ``getVersion()``
public protocol OllamaProtocol: Sendable {
    /// The base URL for the Ollama API server.
    var baseURL: URL { get }

    /// Configuration settings including timeouts, retries, and keep-alive behavior.
    var configuration: OllamaConfiguration { get }

















    /// Lists all models available on the Ollama server.
    ///
    /// - Returns: An array of ``ModelListEntry`` objects containing model information.
    /// - Throws: ``OllamaError`` if the request fails.
    func listModels() async throws -> [ModelListEntry]
























    /// Retrieves detailed information about a specific model.
    ///
    /// - Parameters:
    ///   - name: The model name to query.
    ///   - verbose: When `true`, includes full modelfile details. Defaults to `nil` (non-verbose).
    /// - Returns: A ``ModelInformation`` object containing model details, template, and parameters.
    /// - Throws: ``OllamaError/modelNotFound`` if the model doesn't exist, or other ``OllamaError`` variants.
    func showModel(name: OllamaModelName, verbose: Bool?) async throws -> ModelInformation


























    /// Downloads a model from the Ollama registry.
    ///
    /// Returns a stream of progress updates as the model is downloaded. Each progress update
    /// includes status information and download metrics.
    ///
    /// - Parameters:
    ///   - name: The model name to pull (e.g., "llama3.2:latest").
    ///   - options: Pull options including whether to allow insecure connections.
    /// - Returns: An ``AsyncThrowingStream`` of ``OperationProgress`` objects tracking the download.
    /// - Throws: ``OllamaError`` if the pull operation fails.
    func pullModel(
        name: OllamaModelName,
        options: PullOptions
    ) async throws -> AsyncThrowingStream<OperationProgress, Error>


























    /// Uploads a model to the Ollama registry.
    ///
    /// Returns a stream of progress updates as the model is uploaded. The model name must
    /// include a namespace (e.g., "username/modelname:tag").
    ///
    /// - Parameters:
    ///   - name: The model name to push. Must include a namespace.
    ///   - options: Push options including whether to allow insecure connections.
    /// - Returns: An ``AsyncThrowingStream`` of ``OperationProgress`` objects tracking the upload.
    /// - Throws: ``OllamaError/invalidParameters(_:)`` if the model name lacks a namespace, or other ``OllamaError`` variants.
    func pushModel(
        name: OllamaModelName,
        options: PushOptions
    ) async throws -> AsyncThrowingStream<OperationProgress, Error>





















    /// Creates a copy of an existing model with a new name.
    ///
    /// - Parameters:
    ///   - source: The name of the model to copy.
    ///   - destination: The new name for the copied model.
    /// - Throws: ``OllamaError`` if the copy operation fails.
    func copyModel(source: OllamaModelName, destination: OllamaModelName) async throws


















    /// Deletes a model from the Ollama server.
    ///
    /// - Parameter name: The name of the model to delete.
    /// - Throws: ``OllamaError/modelNotFound`` if the model doesn't exist, or other ``OllamaError`` variants.
    func deleteModel(name: OllamaModelName) async throws























    /// Lists currently running models on the Ollama server.
    ///
    /// Returns information about models that are currently loaded in memory, including
    /// memory usage and expiration times.
    ///
    /// - Returns: An array of ``RunningModelInfo`` objects.
    /// - Throws: ``OllamaError`` if the request fails.
    func listRunningModels() async throws -> [RunningModelInfo]























    /// Creates a new model from a Modelfile.
    ///
    /// Returns a stream of progress updates as the model is created. The request can specify
    /// a base model, files, adapters, templates, and other configuration options.
    ///
    /// - Parameter request: A ``CreateModelRequest`` containing the model configuration.
    /// - Returns: An ``AsyncThrowingStream`` of ``OperationProgress`` objects tracking creation progress.
    /// - Throws: ``OllamaError`` if the model creation fails.
    func createModel(_ request: CreateModelRequest) async throws -> AsyncThrowingStream<OperationProgress, Error>
















    /// Checks whether a blob exists on the Ollama server.
    ///
    /// Blobs are used to store model layers and other binary data. The digest must be in the
    /// format `sha256:<hex>` or `sha512:<hex>`.
    ///
    /// - Parameter digest: The blob digest to check (e.g., "sha256:abc123...").
    /// - Returns: `true` if the blob exists, `false` otherwise.
    /// - Throws: ``OllamaError/invalidParameters(_:)`` if the digest format is invalid, or other ``OllamaError`` variants.
    func checkBlobExists(digest: String) async throws -> Bool


















    /// Uploads a blob to the Ollama server.
    ///
    /// Blobs are used to store model layers and other binary data. The digest must match
    /// the content's hash and be in the format `sha256:<hex>` or `sha512:<hex>`.
    ///
    /// - Parameters:
    ///   - digest: The blob digest identifying the content (e.g., "sha256:abc123...").
    ///   - data: The binary data to upload.
    /// - Throws: ``OllamaError/invalidParameters(_:)`` if the digest format is invalid, or other ``OllamaError`` variants.
    func pushBlob(digest: String, data: Data) async throws















    /// Retrieves the Ollama server version.
    ///
    /// - Returns: A ``VersionResponse`` containing the server version string.
    /// - Throws: ``OllamaError`` if the request fails.
    func getVersion() async throws -> VersionResponse
}
