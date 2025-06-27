import Foundation

extension OllamaClient {
    
    public func listModels() async throws -> [ModelListEntry] {
        let data = try await makeRequest(endpoint: "tags")
        let response = try decode(data, as: ModelsResponse.self)
        return response.models
    }

    public func showModel(name: OllamaModelName, verbose: Bool? = nil) async throws -> ModelInformation {
        let request = ShowModelRequest(model: name.fullName, verbose: verbose)
        let data = try await makeRequest(
            endpoint: "show",
            method: "POST",
            body: try encode(request)
        )

        do {
            let info = try decoder.decode(ModelInformation.self, from: data)
            return info
        } catch {
            throw OllamaError.decodingError(error)
        }
    }

    public func pullModel(
        name: OllamaModelName,
        options: PullOptions
    ) async throws -> AsyncThrowingStream<OperationProgress, Error> {
        let request = PullModelRequest(
            name: name.fullName,
            insecure: options.allowInsecure,
            stream: true
        )

        return streamRequest(
            endpoint: "pull",
            method: "POST",
            body: try encode(request),
            as: OperationProgress.self
        )
    }

    public func pushModel(
        name: OllamaModelName,
        options: PushOptions
    ) async throws -> AsyncThrowingStream<OperationProgress, Error> {
        // Validate model name has namespace
        guard name.namespace != nil else {
            throw OllamaError.invalidParameters("Model name must include namespace for pushing")
        }

        let request = PushModelRequest(
            name: name.fullName,
            insecure: options.allowInsecure,
            stream: true
        )

        return streamRequest(
            endpoint: "push",
            method: "POST",
            body: try encode(request),
            as: OperationProgress.self
        )
    }

    public func copyModel(
        source: OllamaModelName,
        destination: OllamaModelName
    ) async throws {
        let request = CopyModelRequest(
            source: source.fullName,
            destination: destination.fullName
        )

        _ = try await makeRequest(
            endpoint: "copy",
            method: "POST",
            body: try encode(request)
        )
    }

    public func deleteModel(name: OllamaModelName) async throws {
        let request = DeleteModelRequest(name: name.fullName)
        _ = try await makeRequest(
            endpoint: "delete",
            method: "DELETE",
            body: try encode(request)
        )
    }

    public func listRunningModels() async throws -> [RunningModelInfo] {
        let data = try await makeRequest(endpoint: "ps")
        let response = try decode(data, as: RunningModelsResponse.self)
        return response.models
    }
    
    public func createModel(_ request: CreateModelRequest) async throws -> AsyncThrowingStream<OperationProgress, Error> {
        return streamRequest(
            endpoint: "create",
            method: "POST",
            body: try encode(request),
            as: OperationProgress.self
        )
    }
    
    public func checkBlobExists(digest: String) async throws -> Bool {
        do {
            _ = try await makeRequest(
                endpoint: "blobs/\(digest)",
                method: "HEAD"
            )
            return true
        } catch {
            // Check if it's a 404 error
            if let ollamaError = error as? OllamaError,
               case .serverError(let message) = ollamaError,
               message.contains("404") || message.contains("Not Found") {
                return false
            }
            throw error
        }
    }
    
    public func pushBlob(digest: String, data: Data) async throws {
        _ = try await makeRequest(
            endpoint: "blobs/\(digest)",
            method: "POST",
            body: data
        )
    }
    
    public func getVersion() async throws -> VersionResponse {
        let data = try await makeRequest(endpoint: "version")
        return try decode(data, as: VersionResponse.self)
    }
}

private struct PullModelRequest: Codable {
    let name: String
    let insecure: Bool
    let stream: Bool
}

private struct PushModelRequest: Codable {
    let name: String
    let insecure: Bool
    let stream: Bool
}

private struct CopyModelRequest: Codable {
    let source: String
    let destination: String
}

private struct DeleteModelRequest: Codable {
    let name: String
}

/// Options for pulling models
public struct PullOptions {
    /// Whether to allow insecure connections
    public let allowInsecure: Bool

    public init(allowInsecure: Bool = false) {
        self.allowInsecure = allowInsecure
    }
}

/// Options for pushing models
public struct PushOptions {
    /// Whether to allow insecure connections
    public let allowInsecure: Bool

    public init(allowInsecure: Bool = false) {
        self.allowInsecure = allowInsecure
    }
}
