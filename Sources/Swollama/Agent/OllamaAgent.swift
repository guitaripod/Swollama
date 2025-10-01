import Foundation

/// A thread-safe autonomous agent that combines local chat models with cloud-based web search.
///
/// `OllamaAgent` orchestrates multi-step workflows where a language model can autonomously search
/// the web, fetch pages, and synthesize information to answer complex queries. The agent operates
/// in a loop, allowing the model to make multiple tool calls until it has enough information to
/// provide a complete answer.
///
/// ## Overview
///
/// The agent workflow:
/// 1. Sends the user's prompt to the local Ollama model
/// 2. Model decides whether to call tools (web search/fetch) or answer directly
/// 3. If tools are called, executes them via ``OllamaWebSearchClient``
/// 4. Feeds results back to the model
/// 5. Repeats until the model provides a final answer or hits iteration limit
///
/// All steps emit ``AgentEvent`` values through an `AsyncThrowingStream`, allowing you to observe
/// the agent's reasoning, tool usage, and responses in real-time.
///
/// ## Example
///
/// ```swift
/// let agent = OllamaAgent(webSearchAPIKey: "your_api_key")
///
/// guard let model = OllamaModelName.parse("qwen3:4b") else {
///     throw OllamaError.invalidParameters("Invalid model")
/// }
///
/// for try await event in agent.run(prompt: "What are the latest Swift features?", model: model) {
///     switch event {
///     case .thinking(let text):
///         print("Thinking: \(text)")
///     case .toolCall(let name, _):
///         print("Using tool: \(name)")
///     case .message(let answer):
///         print("Answer: \(answer)")
///     case .done:
///         print("Complete")
///     default:
///         break
///     }
/// }
/// ```
///
/// - Note: As an actor, all method calls must use `await`.
/// - Important: Requires an Ollama API key for web search functionality. Get one at https://ollama.com/settings/keys
public actor OllamaAgent {
    /// The local Ollama client for chat operations.
    public let client: OllamaClient

    /// The cloud web search client for tool execution.
    public let webSearch: OllamaWebSearchClient

    private let configuration: AgentConfiguration

    /// Creates a new autonomous agent.
    ///
    /// - Parameters:
    ///   - client: The local Ollama client to use. Defaults to a new ``OllamaClient`` instance.
    ///   - webSearchAPIKey: Your Ollama API key for web search capabilities.
    ///   - configuration: Agent behavior configuration. Defaults to ``AgentConfiguration/default``.
    public init(
        client: OllamaClient = OllamaClient(),
        webSearchAPIKey: String,
        configuration: AgentConfiguration = .default
    ) {
        self.client = client
        self.webSearch = OllamaWebSearchClient(apiKey: webSearchAPIKey)
        self.configuration = configuration
    }

    /// Runs the agent workflow for a given prompt.
    ///
    /// Executes an autonomous workflow where the model can search the web and fetch pages to gather
    /// information before providing an answer. The method returns immediately with an `AsyncThrowingStream`
    /// that emits events as the agent progresses.
    ///
    /// - Parameters:
    ///   - prompt: The user's query or instruction.
    ///   - model: The Ollama model to use for reasoning and responses.
    /// - Returns: A stream of ``AgentEvent`` values representing the agent's progress.
    /// - Throws: Errors are thrown through the stream, including ``OllamaError/invalidParameters(_:)``
    ///           if the agent reaches the iteration limit without completing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// for try await event in agent.run(prompt: "Explain quantum computing", model: model) {
    ///     switch event {
    ///     case .thinking(let thought):
    ///         print("💭 \(thought)")
    ///     case .toolCall(let name, _):
    ///         print("🔧 Calling \(name)")
    ///     case .message(let answer):
    ///         print("💬 \(answer)")
    ///     case .done:
    ///         print("✅ Done")
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    nonisolated public func run(
        prompt: String,
        model: OllamaModelName
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { [weak self] continuation in
            Task {
                guard let self = self else {
                    continuation.finish()
                    return
                }

                do {
                    var messages: [ChatMessage] = [
                        ChatMessage(role: .user, content: prompt)
                    ]

                    var iterations = 0

                    while iterations < self.configuration.maxIterations {
                        iterations += 1

                        let response = try await self.client.chat(
                            messages: messages,
                            model: model,
                            options: ChatOptions(
                                tools: [
                                    OllamaWebSearchClient.webSearchTool,
                                    OllamaWebSearchClient.webFetchTool
                                ],
                                modelOptions: self.configuration.modelOptions,
                                think: self.configuration.enableThinking
                            )
                        )

                        var accumulatedContent = ""
                        var accumulatedThinking: String?
                        var finalToolCalls: [ToolCall]?
                        var finalRole: MessageRole = .assistant

                        do {
                            for try await chunk in response {
                                if !chunk.message.content.isEmpty {
                                    accumulatedContent += chunk.message.content
                                }

                                if let thinking = chunk.message.thinking {
                                    if accumulatedThinking == nil {
                                        accumulatedThinking = thinking
                                    } else {
                                        accumulatedThinking! += thinking
                                    }
                                }

                                if let toolCalls = chunk.message.toolCalls {
                                    finalToolCalls = toolCalls
                                }

                                finalRole = chunk.message.role
                            }
                        } catch {
                            throw error
                        }

                        let final = ChatMessage(
                            role: finalRole,
                            content: accumulatedContent,
                            toolCalls: finalToolCalls,
                            thinking: accumulatedThinking
                        )

                        if let thinking = final.thinking, !thinking.isEmpty {
                            continuation.yield(.thinking(thinking))
                        }

                        messages.append(final)

                        if let toolCalls = final.toolCalls, !toolCalls.isEmpty {
                            for toolCall in toolCalls {
                                continuation.yield(.toolCall(
                                    name: toolCall.function.name,
                                    arguments: toolCall.function.arguments
                                ))

                                let result = try await self.executeToolCall(toolCall)
                                let truncated = self.truncateIfNeeded(result)

                                continuation.yield(.toolResult(
                                    name: toolCall.function.name,
                                    content: truncated
                                ))

                                messages.append(ChatMessage(
                                    role: .tool,
                                    content: truncated
                                ))
                            }
                        } else {
                            if !final.content.isEmpty {
                                continuation.yield(.message(final.content))
                            }
                            continuation.yield(.done)
                            continuation.finish()
                            return
                        }
                    }

                    throw OllamaError.invalidParameters("Agent reached maximum iterations (\(self.configuration.maxIterations)) without completion")
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func executeToolCall(_ toolCall: ToolCall) async throws -> String {
        let argsData = Data(toolCall.function.arguments.utf8)
        let args = try JSONSerialization.jsonObject(with: argsData) as? [String: Any] ?? [:]

        switch toolCall.function.name {
        case "web_search":
            guard let query = args["query"] as? String else {
                throw OllamaError.invalidParameters("Missing 'query' parameter for web_search")
            }
            let maxResults = args["max_results"] as? Int
            let response = try await self.webSearch.webSearch(query: query, maxResults: maxResults)
            let data = try JSONEncoder().encode(response)
            return String(data: data, encoding: .utf8) ?? "{}"

        case "web_fetch":
            guard let url = args["url"] as? String else {
                throw OllamaError.invalidParameters("Missing 'url' parameter for web_fetch")
            }
            let response = try await self.webSearch.webFetch(url: url)
            let data = try JSONEncoder().encode(response)
            return String(data: data, encoding: .utf8) ?? "{}"

        default:
            throw OllamaError.invalidParameters("Unknown tool: \(toolCall.function.name)")
        }
    }

    nonisolated private func truncateIfNeeded(_ content: String) -> String {
        guard let maxLength = configuration.truncateResults else {
            return content
        }
        if content.count > maxLength {
            return String(content.prefix(maxLength))
        }
        return content
    }
}
