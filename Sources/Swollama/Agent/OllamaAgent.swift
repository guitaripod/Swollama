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

                    while iterations < configuration.maxIterations {
                        iterations += 1

                        let response = try await self.client.chat(
                            messages: messages,
                            model: model,
                            options: ChatOptions(
                                tools: [
                                    OllamaWebSearchClient.webSearchTool,
                                    OllamaWebSearchClient.webFetchTool
                                ],
                                modelOptions: await self.configuration.modelOptions,
                                think: await self.configuration.enableThinking
                            )
                        )

                        var finalResponse: ChatResponse?
                        for try await chunk in response {
                            finalResponse = chunk
                        }

                        guard let final = finalResponse else {
                            throw OllamaError.invalidResponse
                        }

                        if let thinking = final.message.thinking, !thinking.isEmpty {
                            continuation.yield(.thinking(thinking))
                        }

                        messages.append(final.message)

                        if let toolCalls = final.message.toolCalls, !toolCalls.isEmpty {
                            for toolCall in toolCalls {
                                continuation.yield(.toolCall(
                                    name: toolCall.function.name,
                                    arguments: toolCall.function.arguments
                                ))

                                let result = try await self.executeToolCall(toolCall)
                                let truncated = await self.truncateIfNeeded(result)

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
                            if !final.message.content.isEmpty {
                                continuation.yield(.message(final.message.content))
                            }
                            continuation.yield(.done)
                            continuation.finish()
                            return
                        }
                    }

                    throw OllamaError.invalidParameters("Agent reached maximum iterations (\(await self.configuration.maxIterations)) without completion")
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

    private func truncateIfNeeded(_ content: String) async -> String {
        guard let maxLength = await configuration.truncateResults else {
            return content
        }
        if content.count > maxLength {
            return String(content.prefix(maxLength))
        }
        return content
    }
}
