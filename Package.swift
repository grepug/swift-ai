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
            name: "SwiftAIVapor",
            targets: ["SwiftAIVapor"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/grepug/event-source.git", branch: "master"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.6.1"),
        .package(url: "https://github.com/grepug/concurrency-utils.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftAI",
            path: "Sources/Core"
        ),
        .target(
            name: "SwiftAIVapor",
            dependencies: [
                "SwiftAI",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "ConcurrencyUtils", package: "concurrency-utils"),
            ],
            path: "Sources/SwiftAIVapor"
        ),
        .testTarget(
            name: "swift-aiTests",
            dependencies: [
                "SwiftAI",
                .product(name: "EventSource", package: "event-source"),
            ]
        ),
    ]
)
