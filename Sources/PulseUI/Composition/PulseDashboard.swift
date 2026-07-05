import SwiftUI
import PulseCore
import PulseProviders

/// The composition root: the one place that wires concrete providers and caches
/// into view models, then into the type-erased `DashboardModule` descriptors the
/// UI renders. Nothing else in `PulseUI` names a concrete provider — that's what
/// keeps `DashboardView` a pure function of config and payloads.
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
