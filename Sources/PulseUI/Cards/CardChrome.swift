import SwiftUI
import PulseCore

/// Shared card frame: title, accent stripe, and the module's content.
struct ModuleCard<Content: View>: View {
    let title: String
    let accent: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 4, height: 16)
                Text(title)
                    .font(.headline)
                Spacer(minLength: 0)
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        )
    }
}

/// The honesty chip: fresh data shows its age, cached data says so plainly.
struct StalenessChip: View {
    let fetchedAt: Date
    let isStale: Bool
    var now: Date = Date()

    var body: some View {
        Label(text, systemImage: isStale ? "wifi.slash" : "clock")
            .font(.caption2)
            .foregroundStyle(isStale ? .orange : .secondary)
    }

    private var text: String {
        let minutes = max(0, Int(now.timeIntervalSince(fetchedAt) / 60))
        let age = minutes < 60 ? "\(minutes)m ago" : "\(minutes / 60)h ago"
        return isStale ? "Offline — showing data from \(age)" : "Updated \(age)"
    }
}

/// Loading and failure states share one look across all modules.
struct ModulePlaceholder: View {
    enum Kind { case loading, failed(String) }
    let kind: Kind

    var body: some View {
        switch kind {
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
