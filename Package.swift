// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyShaderView",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "EasyShaderView",
            targets: ["EasyShaderView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/yukiny0811/TransformUtils", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/yukiny0811/MetalVertexHelper", .upToNextMajor(from: "1.0.2")),
    ],
    targets: [
        .target(
            name: "EasyShaderView",
            dependencies: [
                .product(name: "TransformUtils", package: "TransformUtils"),
                .product(name: "MetalVertexHelper", package: "MetalVertexHelper"),
            ],
            resources: [
                .process("Shaders")
            ]
        ),
    ]
)
