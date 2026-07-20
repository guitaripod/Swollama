// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "Swollama",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Swollama",
            targets: ["Swollama"]
        ),
        .executable(
            name: "SwollamaCLI",
            targets: ["SwollamaCLI"]
        ),
    ],
    targets: [
        .target(
            name: "Swollama"
        ),
        .executableTarget(
            name: "SwollamaCLI",
            dependencies: ["Swollama"]
        ),
        .testTarget(
            name: "SwollamaTests",
            dependencies: ["Swollama"]
        ),
    ]
)

// The DocC plugin is only needed to generate documentation in CI. Gate it behind an
// environment variable so consumers of Swollama pull in zero external dependencies.
if ProcessInfo.processInfo.environment["SWOLLAMA_DOCS"] != nil {
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    )
}
