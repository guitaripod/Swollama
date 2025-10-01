#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

private struct InvalidResponseTypeError: Error {}

/// A thread-safe client for the Ollama cloud web search API.
///
/// `OllamaWebSearchClient` provides access to Ollama's cloud-based web search and web fetch capabilities,
/// enabling models to search the web for current information and retrieve full page content. This is separate
/// from the local ``OllamaClient`` and requires an API key for authentication.
///
/// ## Overview
///
/// The client supports two main operations:
/// - Web search: Query the web for relevant pages matching a search term
/// - Web fetch: Extract full content and links from a specific URL
///
/// ## Authentication
///
/// Requires an Ollama API key. Get one at: https://ollama.com/settings/keys
///
/// ## Example
///
/// ```swift
/// let client = OllamaWebSearchClient(apiKey: "your_api_key")
///
/// let results = try await client.webSearch(query: "Swift actors", maxResults: 5)
/// for result in results.results {
///     print("\(result.title): \(result.url)")
/// }
///
/// let page = try await client.webFetch(url: "https://swift.org")
/// print(page.content)
/// ```
///
/// - Note: As an actor, all method calls must use `await`.
/// - Important: This client connects to Ollama's cloud API, not your local Ollama instance.
public actor OllamaWebSearchClient: Sendable {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession

    /// Creates a new Ollama web search client.
    ///
    /// - Parameters:
    ///   - apiKey: Your Ollama API key for authentication.
    ///   - baseURL: The base URL for the Ollama cloud API. Defaults to `https://ollama.com`.
    ///   - session: The URLSession to use. Defaults to `.shared`.
    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://ollama.com")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    /// Searches the web for information matching a query.
    ///
    /// Returns relevant web pages with titles, URLs, and content snippets.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - maxResults: Maximum number of results to return (default 5, maximum 10).
    /// - Returns: A response containing an array of search results.
    /// - Throws: ``OllamaError/httpError(statusCode:message:)`` if the request fails.
    public func webSearch(
        query: String,
        maxResults: Int? = nil
    ) async throws -> WebSearchResponse {
        let request = WebSearchRequest(query: query, maxResults: maxResults)
        return try await performRequest(path: "/api/web_search", body: request)
    }

    /// Fetches the full content from a specific web page.
    ///
    /// Extracts the page title, main text content, and all links found on the page.
    ///
    /// - Parameter url: The complete URL of the web page to fetch.
    /// - Returns: A response containing the page title, content, and links.
    /// - Throws: ``OllamaError/httpError(statusCode:message:)`` if the request fails.
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
    /// Tool definition for web search function calling.
    ///
    /// Provide this to ``ChatOptions/init(tools:format:modelOptions:keepAlive:think:)`` to enable
    /// the model to search the web for current information.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let options = ChatOptions(tools: [OllamaWebSearchClient.webSearchTool])
    /// let response = try await client.chat(messages: messages, model: model, options: options)
    /// ```
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

    /// Tool definition for web fetch function calling.
    ///
    /// Provide this to ``ChatOptions/init(tools:format:modelOptions:keepAlive:think:)`` to enable
    /// the model to fetch and extract full content from specific URLs.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let options = ChatOptions(tools: [OllamaWebSearchClient.webFetchTool])
    /// let response = try await client.chat(messages: messages, model: model, options: options)
    /// ```
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
