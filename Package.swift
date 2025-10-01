// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Performance optimization flags for Linux
let linuxSwiftSettings: [SwiftSetting] = [
    .unsafeFlags([
        "-cross-module-optimization",
        "-whole-module-optimization",
        "-Osize"
    ], .when(platforms: [.linux], configuration: .release)),
]

let linuxLinkerSettings: [LinkerSetting] = [
    .unsafeFlags([
        "-Xlinker", "-z", "-Xlinker", "relro",
        "-Xlinker", "-z", "-Xlinker", "now"
    ], .when(platforms: [.linux]))
]

let package = Package(
    name: "Swollama",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Swollama",
            targets: ["Swollama"]),
        .executable(
            name: "SwollamaCLI",
            targets: ["SwollamaCLI"])
    ],
    targets: [
        .target(
            name: "Swollama",
            swiftSettings: linuxSwiftSettings,
            linkerSettings: linuxLinkerSettings),
        .executableTarget(
            name: "SwollamaCLI",
            dependencies: ["Swollama"],
            resources: [.copy("README.md")],
            swiftSettings: linuxSwiftSettings,
            linkerSettings: linuxLinkerSettings),
        .testTarget(
            name: "SwollamaTests",
            dependencies: ["Swollama"]
        ),
    ]
)