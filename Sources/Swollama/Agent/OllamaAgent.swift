import Foundation


public actor OllamaAgent {
    public let client: OllamaClient
    public let webSearch: OllamaWebSearchClient
    private let configuration: AgentConfiguration

    public init(
        client: OllamaClient = OllamaClient(),
        webSearchAPIKey: String,
        configuration: AgentConfiguration = .default
    ) {
        self.client = client
        self.webSearch = OllamaWebSearchClient(apiKey: webSearchAPIKey)
        self.configuration = configuration
    }

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
