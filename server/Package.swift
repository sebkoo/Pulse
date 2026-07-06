// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PulseServer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        // The server shares the app's domain model — the same BrandConfig the
        // iOS client decodes is what this service encodes.
        .package(name: "Pulse", path: ".."),
    ],
    targets: [
        .target(
            name: "PulseServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "PulseCore", package: "Pulse"),
            ]
        ),
        .executableTarget(
            name: "pulse-server",
            dependencies: ["PulseServer"]
        ),
        .testTarget(
            name: "PulseServerTests",
            dependencies: [
                "PulseServer",
                .product(name: "XCTVapor", package: "vapor"),
            ]
        ),
    ]
)
