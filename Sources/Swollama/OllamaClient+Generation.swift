#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

extension OllamaClient {











































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
            endpoint: "embeddings",
            method: "POST",
            body: try encode(request)
        )

        return try decode(data, as: EmbeddingResponse.self)
    }
}
