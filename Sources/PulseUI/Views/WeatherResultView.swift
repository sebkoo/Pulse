import SwiftUI
import PulseCore
import PulseProviders

/// Current weather for a searched place. Reuses the dashboard's `ModuleModel`
/// and `WeatherCard` verbatim — only the coordinates change — so the search
/// result and the dashboard card can never drift apart.
struct WeatherResultView: View {
    let place: GeocodedPlace
    var accent: Color = .blue

    @State private var model: ModuleModel<OpenMeteoProvider>

    init(place: GeocodedPlace, accent: Color = .blue, session: URLSession = .shared) {
        self.place = place
        self.accent = accent
        _model = State(initialValue: ModuleModel(
            provider: OpenMeteoProvider(
                latitude: place.latitude,
                longitude: place.longitude,
                session: session
            ),
            cache: PayloadCache(key: "weather-\(place.id)")
        ))
    }

    var body: some View {
        ModuleCard(title: place.displayName, accent: accent) {
            switch model.phase {
            case .loading:
                ModulePlaceholder(kind: .loading)
            case .failed(let message):
                ModulePlaceholder(kind: .failed(message))
            case .loaded(let result):
                WeatherCard(snapshot: result.payload, fetchedAt: result.fetchedAt, isStale: result.isStale)
            }
        }
        .task { await model.load() }
    }
}
