//
//  NetworkingSupport+Streaming.swift
//  Swollama
//
//  True streaming support for Linux using curl
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension NetworkingSupport {
    /// Enhanced streaming implementation that uses curl on Linux for true streaming
    static func enhancedStreamTask(
        session: URLSession,
        for request: URLRequest
    ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
        #if os(Linux)
        // Linux: Use curl for true streaming
        return try await curlStreamTask(for: request)
        #else
        // macOS/iOS: Use native streaming
        return try await streamTask(session: session, for: request)
        #endif
    }
    
    #if os(Linux)
    /// Streaming implementation using curl process for true streaming on Linux
    private static func curlStreamTask(
        for request: URLRequest
    ) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
        guard let url = request.url else {
            throw URLError(.badURL)
        }
        
        // Build curl command
        var curlArgs = [
            "-X", request.httpMethod ?? "GET",
            url.absoluteString,
            "-H", "Content-Type: application/json",
            "-N",          // No buffering
            "--no-buffer", // Disable buffering
            "-s",          // Silent mode
            "-i",          // Include headers in output
            "-w", "\\n\\n__CURL_HTTP_CODE__:%{http_code}" // Add status code at end
        ]
        
        // Add request body if present
        if let httpBody = request.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            curlArgs.append(contentsOf: ["-d", bodyString])
        }
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        process.arguments = curlArgs
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Start process
        try process.run()
        
        // Create stream
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            Task {
                let handle = pipe.fileHandleForReading
                var headerData = Data()
                var headersParsed = false
                var httpResponse: HTTPURLResponse?
                
                // Read data in chunks
                while process.isRunning || handle.availableData.count > 0 {
                    let chunk = handle.availableData
                    
                    if chunk.isEmpty {
                        // Small delay to prevent busy waiting
                        try? await Task.sleep(for: .milliseconds(10))
                        continue
                    }
                    
                    if !headersParsed {
                        // Accumulate header data
                        headerData.append(chunk)
                        
                        // Check for end of headers (double newline)
                        if let headerString = String(data: headerData, encoding: .utf8),
                           let range = headerString.range(of: "\r\n\r\n") ?? headerString.range(of: "\n\n") {
                            // Parse headers
                            let headers = String(headerString[..<range.lowerBound])
                            headersParsed = true
                            
                            // Extract status code
                            var statusCode = 200
                            if let statusLine = headers.split(separator: "\n").first {
                                let parts = statusLine.split(separator: " ")
                                if parts.count >= 2, let code = Int(parts[1]) {
                                    statusCode = code
                                }
                            }
                            
                            // Create HTTP response
                            httpResponse = HTTPURLResponse(
                                url: url,
                                statusCode: statusCode,
                                httpVersion: "HTTP/1.1",
                                headerFields: parseHeaders(from: headers)
                            )
                            
                            // Yield remaining data after headers
                            let bodyStartIndex = headerString.distance(from: headerString.startIndex, to: range.upperBound)
                            if bodyStartIndex < headerData.count {
                                let bodyData = headerData[bodyStartIndex...]
                                if !bodyData.isEmpty {
                                    continuation.yield(Data(bodyData))
                                }
                            }
                        }
                    } else {
                        // Headers already parsed, yield body data
                        // Check if this chunk contains the status code marker
                        if let chunkString = String(data: chunk, encoding: .utf8),
                           chunkString.contains("__CURL_HTTP_CODE__:") {
                            // Extract the actual data before the marker
                            if let markerRange = chunkString.range(of: "\n\n__CURL_HTTP_CODE__:") {
                                let actualData = String(chunkString[..<markerRange.lowerBound])
                                if let data = actualData.data(using: .utf8), !data.isEmpty {
                                    continuation.yield(data)
                                }
                            }
                        } else {
                            continuation.yield(chunk)
                        }
                    }
                }
                
                // Wait for process to complete
                process.waitUntilExit()
                
                if process.terminationStatus != 0 {
                    continuation.finish(throwing: URLError(.unknown))
                } else {
                    continuation.finish()
                }
            }
        }
        
        // Wait a moment to ensure headers are parsed
        try await Task.sleep(for: .milliseconds(100))
        
        // Create a basic response if none was parsed
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        return (stream, response as URLResponse)
    }
    
    /// Parse headers from curl output
    private static func parseHeaders(from headerString: String) -> [String: String] {
        var headers: [String: String] = [:]
        
        let lines = headerString.split(separator: "\n").dropFirst() // Skip status line
        for line in lines {
            if let colonIndex = line.firstIndex(of: ":") {
                let key = line[..<colonIndex].trimmingCharacters(in: .whitespaces)
                let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }
        
        return headers
    }
    #endif
}