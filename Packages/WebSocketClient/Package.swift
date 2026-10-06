// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebSocketClient",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "WebSocketClient",
            targets: ["WebSocketClient"]
        ),
    ],
    targets: [
        .target(
            name: "WebSocketClient"
        ),
        .testTarget(
            name: "WebSocketClientTests",
            dependencies: ["WebSocketClient"]
        ),
    ]
)
