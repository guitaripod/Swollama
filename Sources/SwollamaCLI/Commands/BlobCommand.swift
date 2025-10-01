import Foundation
import Swollama

struct BlobCommand: CommandProtocol {
    private let client: OllamaProtocol

    init(client: OllamaProtocol) {
        self.client = client
    }

    func execute(with arguments: [String]) async throws {
        guard arguments.count >= 1 else {
            printBlobHelp()
            return
        }

        let subcommand = arguments[0]
        let remainingArgs = Array(arguments.dropFirst())

        switch subcommand {
        case "check":
            try await checkBlob(arguments: remainingArgs)
        case "push":
            try await pushBlob(arguments: remainingArgs)
        case "--help", "-h", "help":
            printBlobHelp()
        default:
            throw CLIError.invalidArgument("Unknown blob subcommand: \(subcommand)")
        }
    }

    private func checkBlob(arguments: [String]) async throws {
        guard arguments.count >= 1 else {
            throw CLIError.missingArgument("blob digest")
        }

        let digest = arguments[0]

        if !digest.starts(with: "sha256:") || digest.count != 71 {
            throw CLIError.invalidArgument("Invalid digest format. Must be sha256:<64-hex-chars>")
        }

        print("Checking blob: \(digest)")

        do {
            let exists = try await client.checkBlobExists(digest: digest)
            if exists {
                print("✅ Blob exists on server")
            } else {
                print("❌ Blob not found on server")
            }
        } catch {
            print("❌ Failed to check blob: \(error)")
            throw error
        }
    }

    private func pushBlob(arguments: [String]) async throws {
        guard arguments.count >= 2 else {
            throw CLIError.missingArgument("blob digest and file path")
        }

        let digest = arguments[0]
        let filePath = arguments[1]

        if !digest.starts(with: "sha256:") || digest.count != 71 {
            throw CLIError.invalidArgument("Invalid digest format. Must be sha256:<64-hex-chars>")
        }

        let fileURL = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw CLIError.invalidArgument("File not found: \(filePath)")
        }

        do {
            let fileData = try Data(contentsOf: fileURL)

            let hashValue = fileData.sha256()
            if !hashValue.isEmpty {
                let calculatedDigest = "sha256:" + hashValue

                if calculatedDigest != digest {
                    print("⚠️  Warning: Calculated digest doesn't match provided digest")
                    print("  Provided:   \(digest)")
                    print("  Calculated: \(calculatedDigest)")
                    print("")
                    print("Continue anyway? (y/N): ", terminator: "")

                    if let response = readLine()?.lowercased(), response != "y" {
                        print("Aborted.")
                        return
                    }
                }
            }

            let fileSize = ByteCountFormatter.string(
                fromByteCount: Int64(fileData.count),
                countStyle: .file
            )
            print("Pushing blob: \(digest)")
            print("File: \(filePath) (\(fileSize))")
            print("")

            try await client.pushBlob(digest: digest, data: fileData)
            print("✅ Blob pushed successfully")

        } catch {
            print("❌ Failed to push blob: \(error)")
            throw error
        }
    }

    private func printBlobHelp() {
        print(
            """
            Usage: swollama blob <subcommand> [arguments]

            Manage blobs on the Ollama server.

            Subcommands:
                check <digest>              Check if a blob exists on the server
                push <digest> <file>        Push a blob to the server
                help                        Show this help message

            Examples:
                # Check if a blob exists
                swollama blob check sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2

                # Push a GGUF file as a blob
                swollama blob push sha256:29fdb92e57cf0827ded04ae6461b5931d01fa595843f55d36f5b275a52087dd2 model.gguf

            Note: The digest must be in the format sha256:<64-hex-characters>
            """
        )
    }
}

#if canImport(CryptoKit)
    import CryptoKit
#endif

extension Data {
    func sha256() -> String {
        #if canImport(CryptoKit)

            let hash = SHA256.hash(data: self)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        #else

            print("⚠️  SHA256 verification not available on this platform")
            return ""
        #endif
    }
}
