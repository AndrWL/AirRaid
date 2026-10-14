// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HomeStatusKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "HomeStatusKit",
            targets: ["HomeStatusKit"]
        ),
    ],
    targets: [
        .target(
            name: "HomeStatusKit"
        ),
        .testTarget(
            name: "HomeStatusKitTests",
            dependencies: ["HomeStatusKit"]
        ),
    ]
)
