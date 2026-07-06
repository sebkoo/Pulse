import Vapor
import PulseCore

/// The demo brand registry — the same three brands the screenshots use, served
/// from the API instead of bundled in the app. A real deployment would back
/// this with a database; the route contract wouldn't change.
public enum BrandStore {
    public static let brands: [String: BrandConfig] = [
        "pulse": BrandConfig(),
        "acme": BrandConfig(
            appName: "Acme Field Ops",
            accentColorHex: "#E05910",
            modules: ["earthquakes", "weather"]
        ),
        "marina": BrandConfig(
            appName: "Marina Weather",
            accentColorHex: "#0F766E",
            modules: ["weather"]
        ),
    ]
}

/// Lets Vapor return a `BrandConfig` straight from a route. It's already
/// `Codable` in PulseCore; `Content` just adds the HTTP encoding glue, so the
/// bytes on the wire are exactly what the iOS client decodes.
extension BrandConfig: @retroactive Content {}

/// Wire up the routes. Factored out of the entry point so tests configure an
/// app the same way the server does.
public func configure(_ app: Application) throws {
    app.get("health") { _ in "ok" }

    app.get("brands", ":id") { req -> BrandConfig in
        let id = (req.parameters.get("id") ?? "").lowercased()
        guard let brand = BrandStore.brands[id] else {
            throw Abort(.notFound, reason: "No brand named '\(id)'")
        }
        return brand
    }
}
