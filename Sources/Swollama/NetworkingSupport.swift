//
//  NetworkingSupport.swift
//  Swollama
//
//  Optimized for Linux performance with proper streaming support
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

/// High-performance networking support optimized for Linux
enum NetworkingSupport {
    /// Buffer size for streaming operations (64KB for optimal performance)
    static let streamBufferSize = 65536
    
    /// Creates a URLSession with optimized configuration
    static func createSession(configuration: URLSessionConfiguration) -> URLSession {
        return URLSession(configuration: configuration)
    }
    
    /// Creates an optimized URLSessionConfiguration
    static func createDefaultConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        // Optimize for streaming large responses
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        #if !os(Linux)
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.waitsForConnectivity = false
        #endif
        
        return config
    }
    
    /// High-performance data task implementation
    static func dataTask(
        session: URLSession,
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        // Linux implementation with proper error handling
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = data, let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
        #else
        // Native async/await on Apple platforms
        return try await session.data(for: request)
        #endif
    }
    
    /// Optimized streaming implementation
    static func streamTask(
        session: URLSession,
        for request: URLRequest
    ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
        #if canImport(FoundationNetworking)
        // Linux: Use buffered streaming approach
        let (data, response) = try await dataTask(session: session, for: request)
        
        // Create a stream that yields data in chunks for better performance
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            Task {
                let chunkSize = streamBufferSize
                var offset = 0
                
                while offset < data.count {
                    let end = min(offset + chunkSize, data.count)
                    let chunk = data[offset..<end]
                    continuation.yield(Data(chunk))
                    offset = end
                    
                    // Small delay to prevent overwhelming the consumer
                    try? await Task.sleep(for: .microseconds(100))
                }
                
                continuation.finish()
            }
        }
        
        return (stream, response)
        #else
        // Apple platforms: Use native bytes streaming with buffering
        let (bytes, response) = try await session.bytes(for: request)
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            Task {
                do {
                    var buffer = Data(capacity: streamBufferSize)
                    for try await byte in bytes {
                        buffer.append(byte)
                        if buffer.count >= streamBufferSize {
                            continuation.yield(buffer)
                            buffer = Data(capacity: streamBufferSize)
                        }
                    }
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        return (stream, response)
        #endif
    }
}

