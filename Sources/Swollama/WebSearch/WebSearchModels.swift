import Foundation


public struct WebSearchRequest: Codable, Sendable {
    public let query: String
    public let maxResults: Int?

    private enum CodingKeys: String, CodingKey {
        case query
        case maxResults = "max_results"
    }

    public init(query: String, maxResults: Int? = nil) {
        self.query = query
        self.maxResults = maxResults
    }
}


public struct WebFetchRequest: Codable, Sendable {
    public let url: String

    public init(url: String) {
        self.url = url
    }
}


public struct WebSearchResponse: Codable, Sendable {
    public let results: [WebSearchResult]

    public init(results: [WebSearchResult]) {
        self.results = results
    }
}


public struct WebSearchResult: Codable, Sendable {
    public let title: String
    public let url: String
    public let content: String

    public init(title: String, url: String, content: String) {
        self.title = title
        self.url = url
        self.content = content
    }
}


public struct WebFetchResponse: Codable, Sendable {
    public let title: String
    public let content: String
    public let links: [String]

    public init(title: String, content: String, links: [String]) {
        self.title = title
        self.content = content
        self.links = links
    }
}
