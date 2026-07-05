// Renders README screenshots from the real SwiftUI views with deterministic
// sample data — no simulator, no network. Run:
//
//     swift run pulse-screenshots docs/screenshots
//
// Three brands, one codebase: the point of the whole architecture.

import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import PulseCore
import PulseUI
import PulseProviders

@MainActor
func render(config: BrandConfig, to url: URL) throws {
    // DashboardContentView, not DashboardView: ImageRenderer cannot render
    // ScrollView content, and the content view is exactly what the app draws.
    let view = DashboardContentView(config: config, modules: PulseDashboard.sampleModules())
        .frame(width: 390)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 2

    guard let cgImage = renderer.cgImage else {
        throw RenderError.noImage(url.lastPathComponent)
    }
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else {
        throw RenderError.noDestination(url.lastPathComponent)
    }
    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw RenderError.writeFailed(url.lastPathComponent)
    }
    print("wrote \(url.path)")
}

enum RenderError: Error {
    case noImage(String)
    case noDestination(String)
    case writeFailed(String)
}

let brands: [(file: String, config: BrandConfig)] = [
    ("pulse-default.png", BrandConfig()),
    ("acme-field-ops.png", BrandConfig(
        appName: "Acme Field Ops",
        accentColorHex: "#E05910",
        modules: ["earthquakes", "weather"]
    )),
    ("marina-weather.png", BrandConfig(
        appName: "Marina Weather",
        accentColorHex: "#0F766E",
        modules: ["weather"]
    )),
]

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/screenshots"
let outputDirectory = URL(fileURLWithPath: outputPath, isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for brand in brands {
    try await MainActor.run { [brand] in
        try render(config: brand.config, to: outputDirectory.appendingPathComponent(brand.file))
    }
}
