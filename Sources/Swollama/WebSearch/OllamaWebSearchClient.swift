#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

private struct InvalidResponseTypeError: Error {}


public actor OllamaWebSearchClient: Sendable {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession

    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://ollama.com")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    public func webSearch(
        query: String,
        maxResults: Int? = nil
    ) async throws -> WebSearchResponse {
        let request = WebSearchRequest(query: query, maxResults: maxResults)
        return try await performRequest(path: "/api/web_search", body: request)
    }

    public func webFetch(url: String) async throws -> WebFetchResponse {
        let request = WebFetchRequest(url: url)
        return try await performRequest(path: "/api/web_fetch", body: request)
    }

    private func performRequest<T: Codable, R: Codable>(
        path: String,
        body: T
    ) async throws -> R {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.networkError(InvalidResponseTypeError())
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw OllamaError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            throw OllamaError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(R.self, from: data)
    }
}


extension OllamaWebSearchClient {
    public static let webSearchTool = ToolDefinition(
        type: "function",
        function: FunctionDefinition(
            name: "web_search",
            description: "Search the web for current information about a query. Returns relevant web pages with titles, URLs, and content snippets.",
            parameters: Parameters(
                type: "object",
                properties: [
                    "query": PropertyDefinition(
                        type: "string",
                        description: "The search query to look up on the web"
                    ),
                    "max_results": PropertyDefinition(
                        type: "integer",
                        description: "Maximum number of results to return (default 5, maximum 10)"
                    )
                ],
                required: ["query"]
            )
        )
    )

    public static let webFetchTool = ToolDefinition(
        type: "function",
        function: FunctionDefinition(
            name: "web_fetch",
            description: "Fetch and extract the full content from a specific web page URL. Returns the page title, main content, and all links found on the page.",
            parameters: Parameters(
                type: "object",
                properties: [
                    "url": PropertyDefinition(
                        type: "string",
                        description: "The complete URL of the web page to fetch"
                    )
                ],
                required: ["url"]
            )
        )
    )
}
