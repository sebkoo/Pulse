import SwiftUI
import PulseProviders

/// Renders a `WeatherSnapshot` — pure function of its input, so it previews
/// and screenshots deterministically.
struct WeatherCard: View {
    let snapshot: WeatherSnapshot
    let fetchedAt: Date
    let isStale: Bool
    var now: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(snapshot.temperature.rounded()))\(snapshot.unit)")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                Text(snapshot.condition)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Label("Wind \(Int(snapshot.windSpeed.rounded())) km/h", systemImage: "wind")
                .font(.callout)
                .foregroundStyle(.secondary)
            StalenessChip(fetchedAt: fetchedAt, isStale: isStale, now: now)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
