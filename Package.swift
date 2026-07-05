// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Pulse",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PulseCore", targets: ["PulseCore"]),
        .library(name: "PulseProviders", targets: ["PulseProviders"]),
        .library(name: "PulseUI", targets: ["PulseUI"]),
    ],
    targets: [
        .target(name: "PulseCore"),
        .target(name: "PulseProviders", dependencies: ["PulseCore"]),
        .target(name: "PulseUI", dependencies: ["PulseCore", "PulseProviders"]),
        .testTarget(name: "PulseCoreTests", dependencies: ["PulseCore"]),
    ]
)
