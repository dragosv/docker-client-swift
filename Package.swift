// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "docker-client-swift",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "DockerClientSwift", targets: ["DockerClientSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.94.1"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.31.0"),
    ],
    targets: [
        .target(
            name: "DockerClientSwift",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]),
        .testTarget(
            name: "DockerClientTests",
            dependencies: ["DockerClientSwift"]
        ),
    ]
)
