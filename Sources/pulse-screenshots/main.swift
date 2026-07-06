// Renders README screenshots from the real SwiftUI views with deterministic
// sample data — no simulator, no network. Run:
//
//     swift run pulse-screenshots docs/screenshots
//
// Three brands plus the city-search screens, one codebase: the point of the
// whole architecture.

import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import PulseCore
import PulseUI
import PulseProviders

enum RenderError: Error {
    case noImage(String)
    case noDestination(String)
    case writeFailed(String)
}

/// Render any view to a PNG at a fixed phone width. Every sample passed in is a
/// plain, model-free content view — `ImageRenderer` cannot render a `ScrollView`
/// or await a `.task`, so these are exactly what the app draws, minus the async.
@MainActor
func render(_ view: some View, width: CGFloat = 390, to url: URL) throws {
    let renderer = ImageRenderer(content: view.frame(width: width))
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

/// Stitch a sequence of rendered frames into an animated GIF — a start-to-finish
/// walkthrough of the real views, no simulator required. Each frame is already
/// sized, so it goes straight into the GIF with its per-frame dwell time.
@MainActor
func renderGIF(_ frames: [(view: AnyView, seconds: Double)], to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.gif.identifier as CFString, frames.count, nil
    ) else {
        throw RenderError.noDestination(url.lastPathComponent)
    }
    let gifProperties = [
        kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFLoopCount as String: 0,
        ],
    ]
    CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

    for frame in frames {
        let renderer = ImageRenderer(content: frame.view)
        renderer.scale = 2
        guard let cgImage = renderer.cgImage else {
            throw RenderError.noImage(url.lastPathComponent)
        }
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frame.seconds,
            ],
        ]
        CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
    }

    guard CGImageDestinationFinalize(destination) else {
        throw RenderError.writeFailed(url.lastPathComponent)
    }
    print("wrote \(url.path) (\(frames.count) frames)")
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
        try render(
            DashboardContentView(config: brand.config, modules: PulseDashboard.sampleModules()),
            to: outputDirectory.appendingPathComponent(brand.file)
        )
    }
}

try await MainActor.run {
    try render(
        PulseDashboard.sampleCitySearchResults(),
        to: outputDirectory.appendingPathComponent("city-search.png")
    )
    try render(
        PulseDashboard.sampleCitySearchWeather(),
        to: outputDirectory.appendingPathComponent("city-search-weather.png")
    )
    try render(
        PulseDashboard.sampleQuakesDetail(),
        to: outputDirectory.appendingPathComponent("earthquakes-detail.png")
    )
    try render(
        DashboardContentView(config: BrandConfig(), modules: PulseDashboard.sampleFailedModules()),
        to: outputDirectory.appendingPathComponent("state-error.png")
    )
    try renderGIF(
        PulseDashboard.walkthrough(),
        to: outputDirectory.appendingPathComponent("walkthrough.gif")
    )
}
