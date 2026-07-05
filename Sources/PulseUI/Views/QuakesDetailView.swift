import SwiftUI
import PulseCore
import PulseProviders

/// The full list of recent earthquakes — the same rows the dashboard card
/// renders, without its 3-item cap. Owns its own `ModuleModel`, exactly like a
/// live dashboard module.
struct QuakesDetailView: View {
    var accent: Color = .blue

    @State private var model: ModuleModel<USGSQuakesProvider>

    init(accent: Color = .blue, session: URLSession = .shared) {
        self.accent = accent
        _model = State(initialValue: ModuleModel(
            provider: USGSQuakesProvider(session: session),
            cache: PayloadCache(key: "earthquakes")
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                switch model.phase {
                case .loading:
                    ModulePlaceholder(kind: .loading)
                case .failed(let message):
                    ModulePlaceholder(kind: .failed(message))
                case .loaded(let result):
                    ModuleCard(title: "Recent earthquakes", accent: accent) {
                        QuakesCard(
                            quakes: result.payload,
                            fetchedAt: result.fetchedAt,
                            isStale: result.isStale,
                            limit: result.payload.count
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(DashboardContentView.canvas)
        .task { await model.load() }
    }
}
