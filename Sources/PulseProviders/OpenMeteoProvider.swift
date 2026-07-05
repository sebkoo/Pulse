import Foundation
import PulseCore

/// What the weather module renders — already normalized, no optionals the UI
/// has to guard against.
public struct WeatherSnapshot: Codable, Equatable, Sendable {
    public let temperature: Double
    public let unit: String
    public let windSpeed: Double
    public let conditionCode: Int
    public let condition: String

    public init(temperature: Double, unit: String, windSpeed: Double, conditionCode: Int, condition: String) {
        self.temperature = temperature
        self.unit = unit
        self.windSpeed = windSpeed
        self.conditionCode = conditionCode
        self.condition = condition
    }
}

/// Current weather from the free, keyless Open-Meteo API.
///
/// Open-Meteo is free for non-commercial use (see README); a company forking
/// Pulse swaps this file for their commercial provider — the `DataProvider`
/// contract means nothing else changes.
public struct OpenMeteoProvider: DataProvider {
    public enum ProviderError: Error, Equatable {
        case badURL
        case badResponse(status: Int)
        case unusablePayload
    }

    public let id = "weather"
    public let title = "Weather"

    private let latitude: Double
    private let longitude: Double
    private let session: URLSession

    /// Coordinates default to the DC metro area; a later commit reads them
    /// from `Brand.json`. The session is injectable so tests stub the network.
    public init(
        latitude: Double = 38.8462,
        longitude: Double = -77.3064,
        session: URLSession = .shared
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.session = session
    }

    public func fetch() async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m"),
        ]
        guard let url = components?.url else { throw ProviderError.badURL }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ProviderError.badResponse(status: http.statusCode)
        }

        let raw = try JSONDecoder().decode(RawForecast.self, from: data)
        guard let current = raw.current, let temperature = current.temperature else {
            throw ProviderError.unusablePayload
        }

        return WeatherSnapshot(
            temperature: temperature,
            unit: raw.units?.temperature ?? "°C",
            windSpeed: current.windSpeed ?? 0,
            conditionCode: current.weatherCode ?? -1,
            condition: Self.condition(for: current.weatherCode)
        )
    }

    /// Human-readable label for a WMO weather code; unknown codes degrade to
    /// "Unknown" rather than failing the whole payload.
    static func condition(for code: Int?) -> String {
        guard let code else { return "Unknown" }
        switch code {
        case 0: return "Clear sky"
        case 1, 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51...57: return "Drizzle"
        case 61...67: return "Rain"
        case 71...77: return "Snow"
        case 80...82: return "Rain showers"
        case 95...99: return "Thunderstorm"
        default: return "Unknown"
        }
    }

    // MARK: - Wire shapes (honest: everything optional)

    struct RawForecast: Decodable {
        let current: RawCurrent?
        let units: RawUnits?

        enum CodingKeys: String, CodingKey {
            case current
            case units = "current_units"
        }
    }

    struct RawCurrent: Decodable {
        let temperature: Double?
        let weatherCode: Int?
        let windSpeed: Double?

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case weatherCode = "weather_code"
            case windSpeed = "wind_speed_10m"
        }
    }

    struct RawUnits: Decodable {
        let temperature: String?

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
        }
    }
}
