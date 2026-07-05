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
            DashboardModule(id: "weather", title: "Weather", route: .weatherSearch) {
                LiveWeatherModule(session: session)
            },
            DashboardModule(id: "earthquakes", title: "Earthquakes", route: .quakes) {
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

    // MARK: - Screenshot samples

    /// The city search mid-query, showing matched cities. Deterministic and
    /// model-free so `ImageRenderer` can capture it.
    @MainActor
    public static func sampleCitySearchResults() -> some View {
        CitySearchContentView(
            query: .constant("San"),
            phase: .results(SampleData.searchResults),
            staticField: true
        )
        .background(DashboardContentView.canvas)
    }

    /// A city picked from the results, showing its current weather — the same
    /// card the dashboard renders, fixed sample data, no network.
    @MainActor
    public static func sampleCitySearchWeather(now: Date = SampleData.referenceNow) -> some View {
        let place = SampleData.searchResults[0]
        let accent = Color(hex: BrandConfig().accentColorHex, fallback: .blue)
        let detail = AnyView(
            ModuleCard(title: place.displayName, accent: accent) {
                WeatherCard(
                    snapshot: SampleData.weather,
                    fetchedAt: now.addingTimeInterval(-3 * 60),
                    isStale: false,
                    now: now
                )
            }
        )
        return CitySearchContentView(
            query: .constant(place.name),
            phase: .results(SampleData.searchResults),
            detail: detail,
            accent: accent,
            staticField: true
        )
        .background(DashboardContentView.canvas)
    }

    /// The earthquakes detail screen — the full sample list, the same rows
    /// `QuakesDetailView` draws once its model loads. Static so `ImageRenderer`
    /// can capture it.
    @MainActor
    public static func sampleQuakesDetail(now: Date = SampleData.referenceNow) -> some View {
        let accent = Color(hex: BrandConfig().accentColorHex, fallback: .blue)
        return VStack(alignment: .leading, spacing: 14) {
            ModuleCard(title: "Recent earthquakes", accent: accent) {
                QuakesCard(
                    quakes: SampleData.quakes,
                    fetchedAt: now.addingTimeInterval(-6 * 60),
                    isStale: false,
                    now: now,
                    limit: SampleData.quakes.count
                )
            }
        }
        .padding(16)
        .background(DashboardContentView.canvas)
    }
}
