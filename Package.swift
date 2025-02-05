// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ai",
    platforms: [
        .macOS(.v13)
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
    ],
    dependencies: [
        .package(url: "https://github.com/grepug/event-source.git", branch: "master")
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
            ],
            path: "Sources/Client"
        ),
        .target(
            name: "SwiftAIServer",
            dependencies: ["SwiftAI"],
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
