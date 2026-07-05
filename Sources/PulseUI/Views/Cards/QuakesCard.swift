import SwiftUI
import PulseProviders

/// Renders recent earthquakes — magnitude badges plus place and age.
struct QuakesCard: View {
    let quakes: [Quake]
    let fetchedAt: Date
    let isStale: Bool
    var now: Date = Date()
    var limit: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if quakes.isEmpty {
                Text("No significant earthquakes — a quiet planet today.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(quakes.prefix(limit)) { quake in
                    HStack(spacing: 10) {
                        Text(String(format: "M%.1f", quake.magnitude))
                            .font(.callout.weight(.bold).monospacedDigit())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(badgeColor(for: quake.magnitude).opacity(0.15), in: Capsule())
                            .foregroundStyle(badgeColor(for: quake.magnitude))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(quake.place)
                                .font(.callout)
                                .lineLimit(1)
                            Text(ageLabel(for: quake.time))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            StalenessChip(fetchedAt: fetchedAt, isStale: isStale, now: now)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func badgeColor(for magnitude: Double) -> Color {
        switch magnitude {
        case ..<5: return .green
        case ..<6: return .orange
        default: return .red
        }
    }

    private func ageLabel(for time: Date) -> String {
        let hours = max(0, Int(now.timeIntervalSince(time) / 3600))
        return hours < 1 ? "just now" : hours < 24 ? "\(hours)h ago" : "\(hours / 24)d ago"
    }
}
