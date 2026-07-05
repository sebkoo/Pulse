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

public enum PulseDashboard {
    /// The default catalog: every module this build of Pulse knows how to
    /// render. `BrandConfig.modules` picks which of these actually appear.
    /// Adding a provider = adding one entry here; `DashboardView` is untouched.
    @MainActor
    public static func standardModules(session: URLSession = .shared) -> [DashboardModule] {
        [
            DashboardModule(id: "weather", title: "Weather") {
                LiveWeatherModule(session: session)
            },
            DashboardModule(id: "earthquakes", title: "Earthquakes") {
                LiveQuakesModule(session: session)
            },
        ]
    }

    /// Deterministic catalog for previews and screenshot rendering: the same
    /// card views, fixed `SampleData`, zero network. The quakes card is
    /// deliberately rendered stale so the offline chip is visible.
    @MainActor
    public static func sampleModules(now: Date = SampleData.referenceNow) -> [DashboardModule] {
        [
            DashboardModule(id: "weather", title: "Weather") {
                WeatherCard(
                    snapshot: SampleData.weather,
                    fetchedAt: now.addingTimeInterval(-4 * 60),
                    isStale: false,
                    now: now
                )
            },
            DashboardModule(id: "earthquakes", title: "Earthquakes") {
                QuakesCard(
                    quakes: SampleData.quakes,
                    fetchedAt: now.addingTimeInterval(-12 * 60),
                    isStale: true,
                    now: now
                )
            },
        ]
    }

    /// Ready-to-mount root view: brand from the bundle, standard catalog.
    @MainActor
    public static func root(bundle: Bundle = .main) -> some View {
        DashboardView(
            config: BrandConfig.load(fromResource: "Brand", in: bundle),
            modules: standardModules()
        )
    }
}
