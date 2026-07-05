import Foundation

/// The white-label heart of Pulse.
///
/// Everything a company customizes lives in one JSON file — the app's name,
/// its accent color, and which dashboard modules render (matched against
/// `DataProvider.id`). Fork the repo, edit `Brand.json`, ship your own app.
///
/// Every field decodes with a default, so a partial or missing config can
/// only ever downgrade the experience — branding can never crash the app.
public struct BrandConfig: Codable, Equatable, Sendable {
    public var appName: String
    public var accentColorHex: String
    /// Provider ids to render, in order. Unknown ids are ignored by the UI.
    public var modules: [String]

    public init(
        appName: String = "Pulse",
        accentColorHex: String = "#1F3A5F",
        modules: [String] = ["weather", "earthquakes"]
    ) {
        self.appName = appName
        self.accentColorHex = accentColorHex
        self.modules = modules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = BrandConfig()
        self.appName = try container.decodeIfPresent(String.self, forKey: .appName)
            ?? fallback.appName
        self.accentColorHex = try container.decodeIfPresent(String.self, forKey: .accentColorHex)
            ?? fallback.accentColorHex
        // Module ids are normalized to lowercase so Brand.json is forgiving
        // about casing; empty entries are dropped.
        self.modules = (try container.decodeIfPresent([String].self, forKey: .modules)
            ?? fallback.modules)
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    /// Load a brand config from JSON data, falling back to defaults on any
    /// failure. A broken brand file is a downgrade, never a crash.
    public static func load(from data: Data?) -> BrandConfig {
        guard
            let data,
            let config = try? JSONDecoder().decode(BrandConfig.self, from: data)
        else { return BrandConfig() }
        return config
    }

    /// Convenience for loading `Brand.json` from a bundle.
    public static func load(fromResource name: String = "Brand", in bundle: Bundle) -> BrandConfig {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            return BrandConfig()
        }
        return load(from: try? Data(contentsOf: url))
    }
}
