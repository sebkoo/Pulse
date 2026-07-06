import Foundation
import PulseCore

/// The BFF's aggregated payload: a brand plus only the modules it asked for,
/// already in order. One round-trip fills the whole dashboard, so the client
/// doesn't fan out to each API itself.
public struct Feed: Codable, Equatable, Sendable {
    public let brand: BrandConfig
    public let modules: [FeedModule]

    public init(brand: BrandConfig, modules: [FeedModule]) {
        self.brand = brand
        self.modules = modules
    }
}

/// One module's slice of the feed. Exactly one payload is populated, matching
/// `id` — the client renders whichever it finds.
public struct FeedModule: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let weather: WeatherSnapshot?
    public let quakes: [Quake]?

    public init(id: String, weather: WeatherSnapshot? = nil, quakes: [Quake]? = nil) {
        self.id = id
        self.weather = weather
        self.quakes = quakes
    }
}

/// Fetches the aggregated feed from the BFF. Throws typed errors like the other
/// providers; a caller that wants to stay up when the BFF is down falls back to
/// the per-module providers, which cache offline-first on their own.
public struct FeedProvider: Sendable {
    public enum ProviderError: Error, Equatable {
        case badResponse(status: Int)
    }

    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func feed(brandId: String) async throws -> Feed {
        let url = baseURL.appending(path: "feed").appending(path: brandId)
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ProviderError.badResponse(status: http.statusCode)
        }
        return try Self.decoder.decode(Feed.self, from: data)
    }

    /// The BFF sends quake times as ISO-8601 with fractional seconds
    /// (`toISOString()`), which the stock `.iso8601` strategy rejects — so parse
    /// both, fractional first.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = withFraction.date(from: string) ?? plain.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Not an ISO-8601 date: \(string)"
            )
        }
        return decoder
    }()
}
