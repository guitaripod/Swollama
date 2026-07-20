import Foundation

extension OllamaProtocol {

    /// Generates text and returns the complete output once the model has finished.
    ///
    /// A non-streaming convenience over ``generateText(prompt:model:options:)`` that accumulates the
    /// streamed chunks and returns the full text. Use the streaming variant when you want to display
    /// output as it is produced.
    ///
    /// - Parameters:
    ///   - prompt: The text prompt to send to the model.
    ///   - model: The model to use for generation.
    ///   - options: Generation options. Defaults to ``GenerationOptions/default``.
    /// - Returns: The complete generated text.
    /// - Throws: ``OllamaError`` if the request fails.
    public func completeText(
        prompt: String,
        model: OllamaModelName,
        options: GenerationOptions = .default
    ) async throws -> String {
        var text = ""
        for try await chunk in try await generateText(
            prompt: prompt,
            model: model,
            options: options
        ) {
            text += chunk.response
        }
        return text
    }

    /// Runs a chat completion and returns the assembled assistant message once finished.
    ///
    /// A non-streaming convenience over ``chat(messages:model:options:)`` that accumulates the
    /// streamed chunks into a single ``ChatMessage``. Use the streaming variant when you want to
    /// display the reply as it is produced.
    ///
    /// - Parameters:
    ///   - messages: The conversation history.
    ///   - model: The model to use for the completion.
    ///   - options: Chat options. Defaults to ``ChatOptions/default``.
    /// - Returns: The complete assistant ``ChatMessage``.
    /// - Throws: ``OllamaError`` if the request fails.
    public func completeChat(
        messages: [ChatMessage],
        model: OllamaModelName,
        options: ChatOptions = .default
    ) async throws -> ChatMessage {
        var content = ""
        var thinking = ""
        var role: MessageRole = .assistant
        for try await chunk in try await chat(messages: messages, model: model, options: options) {
            role = chunk.message.role
            content += chunk.message.content
            if let part = chunk.message.thinking { thinking += part }
        }
        return ChatMessage(
            role: role,
            content: content,
            thinking: thinking.isEmpty ? nil : thinking
        )
    }
}

extension AsyncSequence {

    /// Collects every element of the sequence into an array, awaiting completion.
    ///
    /// Convenient for draining a streaming response when you do not need incremental delivery, e.g.
    /// `let chunks = try await client.generateText(prompt: p, model: m).collect()`.
    ///
    /// - Returns: All elements produced by the sequence, in order.
    /// - Throws: Rethrows any error thrown by the underlying sequence.
    public func collect() async rethrows -> [Element] {
        var result: [Element] = []
        for try await element in self {
            result.append(element)
        }
        return result
    }
}
