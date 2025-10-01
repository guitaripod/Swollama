import Foundation

/// Request for searching the web for current information.
///
/// Use this to query the Ollama web search API for relevant web pages matching a search query.
///
/// ## Example
///
/// ```swift
/// let request = WebSearchRequest(query: "Swift concurrency", maxResults: 5)
/// let response = try await webSearchClient.webSearch(query: request.query, maxResults: request.maxResults)
/// ```
public struct WebSearchRequest: Codable, Sendable {
    /// The search query to look up on the web.
    public let query: String

    /// Maximum number of results to return (default 5, maximum 10).
    public let maxResults: Int?

    private enum CodingKeys: String, CodingKey {
        case query
        case maxResults = "max_results"
    }

    /// Creates a web search request.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - maxResults: Optional maximum number of results (defaults to 5 if not specified).
    public init(query: String, maxResults: Int? = nil) {
        self.query = query
        self.maxResults = maxResults
    }
}

/// Request for fetching the full content from a specific web page.
///
/// Use this to extract the complete text content and links from a given URL.
///
/// ## Example
///
/// ```swift
/// let request = WebFetchRequest(url: "https://example.com/article")
/// let response = try await webSearchClient.webFetch(url: request.url)
/// ```
public struct WebFetchRequest: Codable, Sendable {
    /// The complete URL of the web page to fetch.
    public let url: String

    /// Creates a web fetch request.
    ///
    /// - Parameter url: The complete URL to fetch.
    public init(url: String) {
        self.url = url
    }
}

/// Response containing web search results.
///
/// Contains an array of search results with titles, URLs, and content snippets from relevant web pages.
public struct WebSearchResponse: Codable, Sendable {
    /// Array of search results matching the query.
    public let results: [WebSearchResult]

    /// Creates a web search response.
    ///
    /// - Parameter results: Array of search results.
    public init(results: [WebSearchResult]) {
        self.results = results
    }
}

/// A single search result from a web search query.
///
/// Contains the title, URL, and content snippet from a web page matching the search query.
public struct WebSearchResult: Codable, Sendable {
    /// The title of the web page.
    public let title: String

    /// The URL of the web page.
    public let url: String

    /// A content snippet or excerpt from the web page.
    public let content: String

    /// Creates a web search result.
    ///
    /// - Parameters:
    ///   - title: The page title.
    ///   - url: The page URL.
    ///   - content: A content snippet from the page.
    public init(title: String, url: String, content: String) {
        self.title = title
        self.url = url
        self.content = content
    }
}

/// Response containing the full content from a fetched web page.
///
/// Includes the page title, main text content, and all links found on the page.
public struct WebFetchResponse: Codable, Sendable {
    /// The title of the web page.
    public let title: String

    /// The main text content extracted from the page.
    public let content: String

    /// All links found on the page.
    public let links: [String]

    /// Creates a web fetch response.
    ///
    /// - Parameters:
    ///   - title: The page title.
    ///   - content: The extracted text content.
    ///   - links: All links found on the page.
    public init(title: String, content: String, links: [String]) {
        self.title = title
        self.content = content
        self.links = links
    }
}
