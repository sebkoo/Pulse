import SwiftUI
import PulseCore
import PulseProviders

/// Live module card: owns a `ModuleModel` and renders its phases.
struct LiveWeatherModule: View {
    @State private var model: ModuleModel<OpenMeteoProvider>

    init(session: URLSession = .shared) {
        _model = State(initialValue: ModuleModel(
            provider: OpenMeteoProvider(session: session),
            cache: PayloadCache(key: "weather")
        ))
    }

    var body: some View {
        Group {
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

struct LiveQuakesModule: View {
    @State private var model: ModuleModel<USGSQuakesProvider>

    init(session: URLSession = .shared) {
        _model = State(initialValue: ModuleModel(
            provider: USGSQuakesProvider(session: session),
            cache: PayloadCache(key: "earthquakes")
        ))
    }

    var body: some View {
        Group {
            switch model.phase {
            case .loading:
                ModulePlaceholder(kind: .loading)
            case .failed(let message):
                ModulePlaceholder(kind: .failed(message))
            case .loaded(let result):
                QuakesCard(quakes: result.payload, fetchedAt: result.fetchedAt, isStale: result.isStale)
            }
        }
        .task { await model.load() }
    }
}
