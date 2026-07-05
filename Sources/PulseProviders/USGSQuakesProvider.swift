import Foundation
import PulseCore

/// One earthquake the dashboard can render as-is.
public struct Quake: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let magnitude: Double
    public let place: String
    public let time: Date

    public init(id: String, magnitude: Double, place: String, time: Date) {
        self.id = id
        self.magnitude = magnitude
        self.place = place
        self.time = time
    }
}

/// Recent earthquakes from the USGS real-time GeoJSON feeds (free, no key —
/// US government public data).
public struct USGSQuakesProvider: DataProvider {
    /// The USGS summary feeds this provider can read.
    public enum Feed: String, Sendable {
        case significantWeek = "significant_week"
        case magnitude45Day = "4.5_day"
        case allDay = "all_day"
    }

    public enum ProviderError: Error, Equatable {
        case badURL
        case badResponse(status: Int)
        case unusablePayload
    }

    public let id = "earthquakes"
    public let title = "Earthquakes"

    private let feed: Feed
    private let session: URLSession

    public init(feed: Feed = .magnitude45Day, session: URLSession = .shared) {
        self.feed = feed
        self.session = session
    }

    public func fetch() async throws -> [Quake] {
        let urlString = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/\(feed.rawValue).geojson"
        guard let url = URL(string: urlString) else { throw ProviderError.badURL }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ProviderError.badResponse(status: http.statusCode)
        }

        let raw = try JSONDecoder().decode(RawFeed.self, from: data)
        guard let features = raw.features else { throw ProviderError.unusablePayload }

        // Normalize at the boundary: drop features missing the essentials,
        // convert epoch-milliseconds to Date, newest first. An empty list is
        // a legitimate result (a quiet planet), not an error.
        return features
            .compactMap { feature -> Quake? in
                guard
                    let id = feature.id, !id.isEmpty,
                    let properties = feature.properties,
                    let magnitude = properties.mag,
                    let place = properties.place, !place.isEmpty,
                    let milliseconds = properties.time
                else { return nil }
                return Quake(
                    id: id,
                    magnitude: magnitude,
                    place: place,
                    time: Date(timeIntervalSince1970: Double(milliseconds) / 1000)
                )
            }
            .sorted { $0.time > $1.time }
    }

    // MARK: - Wire shapes (honest: everything optional)

    struct RawFeed: Decodable {
        let features: [RawFeature]?
    }

    struct RawFeature: Decodable {
        let id: String?
        let properties: RawProperties?
    }

    struct RawProperties: Decodable {
        let mag: Double?
        let place: String?
        let time: Int64?
    }
}
