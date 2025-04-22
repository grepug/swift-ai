// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ai",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftAI",
            targets: ["SwiftAI"]
        ),
        .library(
            name: "SwiftAIServer",
            targets: ["SwiftAIServer"]
        ),
        .library(
            name: "SwiftAIClient",
            targets: ["SwiftAIClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/grepug/event-source.git", branch: "master"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/grepug/concurrency-utils.git", branch: "main"),
        .package(url: "https://github.com/FlineDev/ErrorKit.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftAI",
            path: "Sources/Core"
        ),
        .target(
            name: "SwiftAIClient",
            dependencies: [
                "SwiftAI",
                .product(name: "EventSource", package: "event-source"),
                .product(name: "ConcurrencyUtils", package: "concurrency-utils"),
                .product(name: "ErrorKit", package: "ErrorKit"),
            ],
            path: "Sources/Client"
        ),
        .target(
            name: "SwiftAIServer",
            dependencies: [
                "SwiftAI",
                .product(name: "EventSource", package: "event-source"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ConcurrencyUtils", package: "concurrency-utils"),
                .product(name: "ErrorKit", package: "ErrorKit"),
            ],
            path: "Sources/Server"
        ),
        .testTarget(
            name: "swift-aiTests",
            dependencies: [
                "SwiftAI",
                "SwiftAIClient",
                "SwiftAIServer",
                .product(name: "EventSource", package: "event-source"),
            ]
        ),
    ]
)
