#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

extension OllamaClient {











































    /// Generates text completions with streaming responses.
    ///
    /// Sends a prompt to the specified model and returns a stream of incremental response chunks.
    /// Each chunk contains the generated text fragment, allowing for real-time display of the
    /// generation process.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let client = OllamaClient()
    /// let model = OllamaModelName.parse("llama3.2")!
    ///
    /// for try await response in try await client.generateText(
    ///     prompt: "Explain quantum computing",
    ///     model: model
    /// ) {
    ///     print(response.response, terminator: "")
    ///     if response.done {
    ///         print("\nTokens: \(response.evalCount ?? 0)")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - prompt: The text prompt to send to the model.
    ///   - model: The model name to use for generation.
    ///   - options: Generation options including system prompt, format, images, and model parameters. Defaults to ``GenerationOptions/default``.
    /// - Returns: An ``AsyncThrowingStream`` of ``GenerateResponse`` objects. Each response contains incremental text and metadata.
    /// - Throws: ``OllamaError`` if the generation fails.
    public func generateText(
        prompt: String,
        model: OllamaModelName,
        options: GenerationOptions = .default
    ) async throws -> AsyncThrowingStream<GenerateResponse, Error> {
        let request = GenerateRequest(
            model: model.fullName,
            prompt: prompt,
            suffix: options.suffix,
            images: options.images,
            format: options.format,
            options: options.modelOptions,
            system: options.systemPrompt,
            template: options.template,
            context: options.context,
            stream: true,
            raw: options.raw,
            keepAlive: options.keepAlive ?? configuration.defaultKeepAlive,
            think: options.think
        )

        return streamRequest(
            endpoint: "generate",
            method: "POST",
            body: try encode(request),
            as: GenerateResponse.self
        )
    }



















































    /// Generates chat completions with streaming responses.
    ///
    /// Sends a conversation history to the specified model and returns a stream of incremental
    /// response chunks. Supports multi-turn conversations, tool calling, structured outputs,
    /// and multimodal inputs (text + images).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let client = OllamaClient()
    /// let model = OllamaModelName.parse("llama3.2")!
    ///
    /// let messages = [
    ///     ChatMessage(role: .system, content: "You are a helpful assistant."),
    ///     ChatMessage(role: .user, content: "What is the capital of France?")
    /// ]
    ///
    /// for try await response in try await client.chat(
    ///     messages: messages,
    ///     model: model
    /// ) {
    ///     print(response.message.content, terminator: "")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - messages: An array of ``ChatMessage`` objects representing the conversation history.
    ///   - model: The model name to use for the chat completion.
    ///   - options: Chat options including tools, format, and model parameters. Defaults to ``ChatOptions/default``.
    /// - Returns: An ``AsyncThrowingStream`` of ``ChatResponse`` objects. Each response contains incremental message content and metadata.
    /// - Throws: ``OllamaError`` if the chat request fails.
    public func chat(
        messages: [ChatMessage],
        model: OllamaModelName,
        options: ChatOptions = .default
    ) async throws -> AsyncThrowingStream<ChatResponse, Error> {
        let request = ChatRequest(
            model: model.fullName,
            messages: messages,
            tools: options.tools,
            format: options.format,
            options: options.modelOptions,
            stream: true,
            keepAlive: options.keepAlive ?? configuration.defaultKeepAlive,
            think: options.think
        )

        return streamRequest(
            endpoint: "chat",
            method: "POST",
            body: try encode(request),
            as: ChatResponse.self
        )
    }





































    /// Generates vector embeddings for text input.
    ///
    /// Converts text strings into numerical vector representations that can be used for semantic
    /// search, clustering, classification, and other machine learning tasks. Supports both single
    /// strings and batches of strings.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let client = OllamaClient()
    /// let model = OllamaModelName.parse("nomic-embed-text")!
    ///
    /// let response = try await client.generateEmbeddings(
    ///     input: .single("The quick brown fox"),
    ///     model: model
    /// )
    ///
    /// print("Embedding dimensions: \(response.embeddings[0].count)")
    /// ```
    ///
    /// - Parameters:
    ///   - input: The text input to embed, either a single string or an array of strings.
    ///   - model: The embedding model name to use (e.g., "nomic-embed-text").
    ///   - options: Embedding options including truncation and model parameters. Defaults to ``EmbeddingOptions/default``.
    /// - Returns: An ``EmbeddingResponse`` containing the vector embeddings and metadata.
    /// - Throws: ``OllamaError`` if the embedding request fails.
    public func generateEmbeddings(
        input: EmbeddingInput,
        model: OllamaModelName,
        options: EmbeddingOptions = .default
    ) async throws -> EmbeddingResponse {
        let request = EmbeddingRequest(
            model: model.fullName,
            input: input,
            truncate: options.truncate,
            options: options.modelOptions,
            keepAlive: options.keepAlive ?? configuration.defaultKeepAlive
        )

        let data = try await makeRequest(
            endpoint: "embed",
            method: "POST",
            body: try encode(request)
        )

        return try decode(data, as: EmbeddingResponse.self)
    }
}
