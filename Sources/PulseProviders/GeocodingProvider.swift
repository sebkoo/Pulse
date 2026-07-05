import Foundation

/// A place returned by geocoding — already normalized: no optionals the UI has
/// to guard, and coordinates ready to hand to `OpenMeteoProvider`.
public struct GeocodedPlace: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let admin1: String?
    public let country: String?
    public let latitude: Double
    public let longitude: Double

    public init(id: Int, name: String, admin1: String?, country: String?, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.admin1 = admin1
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }

    /// "Ridgecrest, California, United States" — missing parts drop out cleanly.
    public var displayName: String {
        [name, admin1, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

/// City search over the free, keyless Open-Meteo geocoding API.
///
/// A query, not a cached module — so it doesn't implement `DataProvider`. It
/// normalizes the same way the other providers do: everything on the wire is
/// optional, and results missing the essentials are dropped at the boundary.
public struct GeocodingProvider: Sendable {
    public enum ProviderError: Error, Equatable {
        case badURL
        case badResponse(status: Int)
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(_ query: String, count: Int = 5) async throws -> [GeocodedPlace] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // An empty query is a no-op, not a network call and not an error.
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components?.url else { throw ProviderError.badURL }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ProviderError.badResponse(status: http.statusCode)
        }

        let raw = try JSONDecoder().decode(RawGeocoding.self, from: data)
        // Open-Meteo omits "results" entirely when nothing matches — that's an
        // empty list, not an error.
        return (raw.results ?? []).compactMap { result -> GeocodedPlace? in
            guard
                let id = result.id,
                let name = result.name, !name.isEmpty,
                let latitude = result.latitude,
                let longitude = result.longitude
            else { return nil }
            return GeocodedPlace(
                id: id,
                name: name,
                admin1: result.admin1,
                country: result.country,
                latitude: latitude,
                longitude: longitude
            )
        }
    }

    // MARK: - Wire shapes (honest: everything optional)

    struct RawGeocoding: Decodable {
        let results: [RawPlace]?
    }

    struct RawPlace: Decodable {
        let id: Int?
        let name: String?
        let admin1: String?
        let country: String?
        let latitude: Double?
        let longitude: Double?
    }
}
