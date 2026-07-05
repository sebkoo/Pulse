import Foundation
import PulseProviders

/// Deterministic sample payloads for previews and screenshot rendering —
/// real view code, fixed data, zero network.
public enum SampleData {
    public static let referenceNow = Date(timeIntervalSince1970: 1_782_000_000)

    public static let weather = WeatherSnapshot(
        temperature: 27.4,
        unit: "°C",
        windSpeed: 9,
        conditionCode: 2,
        condition: "Partly cloudy"
    )

    public static let quakes: [Quake] = [
        Quake(id: "s1", magnitude: 6.1, place: "98 km SSE of Sand Point, Alaska",
              time: referenceNow.addingTimeInterval(-2 * 3600)),
        Quake(id: "s2", magnitude: 5.2, place: "Kermadec Islands, New Zealand",
              time: referenceNow.addingTimeInterval(-9 * 3600)),
        Quake(id: "s3", magnitude: 4.7, place: "12 km NE of Ridgecrest, CA",
              time: referenceNow.addingTimeInterval(-30 * 3600)),
        Quake(id: "s4", magnitude: 5.8, place: "South of the Fiji Islands",
              time: referenceNow.addingTimeInterval(-41 * 3600)),
        Quake(id: "s5", magnitude: 4.9, place: "64 km W of Cantwell, Alaska",
              time: referenceNow.addingTimeInterval(-52 * 3600)),
        Quake(id: "s6", magnitude: 4.5, place: "near the coast of central Chile",
              time: referenceNow.addingTimeInterval(-70 * 3600)),
    ]

    /// A "San" query, including two same-name cities to show disambiguation.
    public static let searchResults: [GeocodedPlace] = [
        GeocodedPlace(id: 5391959, name: "San Francisco", admin1: "California",
                      country: "United States", latitude: 37.7749, longitude: -122.4194),
        GeocodedPlace(id: 5391811, name: "San Diego", admin1: "California",
                      country: "United States", latitude: 32.7157, longitude: -117.1611),
        GeocodedPlace(id: 5392171, name: "San Jose", admin1: "California",
                      country: "United States", latitude: 37.3382, longitude: -121.8863),
        GeocodedPlace(id: 3621849, name: "San José", admin1: "San José",
                      country: "Costa Rica", latitude: 9.9281, longitude: -84.0907),
    ]
}
