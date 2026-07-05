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
    ]
}
