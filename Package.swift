// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RequestSocket",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "RequestSocket",
            targets: ["RequestSocket"]),
    ],
    targets: [
        .target(
            name: "RequestSocket"),
        .testTarget(
            name: "RequestSocketTests",
            dependencies: ["RequestSocket"]),
    ]
)
