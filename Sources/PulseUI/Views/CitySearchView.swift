import SwiftUI
import PulseProviders

/// Search a city and see its current weather.
///
/// The search box is Combine-backed (`CitySearchModel` debounces keystrokes);
/// the result reuses the dashboard's weather card. The `search` closure is
/// injectable so previews and tests never hit the network.
struct CitySearchView: View {
    var accent: Color = .blue

    @StateObject private var model: CitySearchModel
    @State private var selected: GeocodedPlace?

    init(
        accent: Color = .blue,
        search: @escaping @Sendable (String) async throws -> [GeocodedPlace] = { try await GeocodingProvider().search($0) }
    ) {
        self.accent = accent
        _model = StateObject(wrappedValue: CitySearchModel(search: search))
    }

    var body: some View {
        CitySearchContentView(
            query: $model.query,
            phase: model.phase,
            detail: selected.map { place in
                AnyView(WeatherResultView(place: place, accent: accent).id(place.id))
            },
            accent: accent,
            onSelect: { selected = $0 },
            onClear: {
                model.query = ""
                selected = nil
            },
            onBack: { selected = nil }
        )
    }
}

/// The search screen as a pure function of its inputs — no model, no async — so
/// `ImageRenderer` can screenshot it deterministically. Same reason
/// `DashboardContentView` is split out of `DashboardView`.
struct CitySearchContentView: View {
    @Binding var query: String
    let phase: CitySearchModel.Phase
    var detail: AnyView?
    var accent: Color = .blue
    var onSelect: (GeocodedPlace) -> Void = { _ in }
    var onClear: () -> Void = {}
    var onBack: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchField
            if let detail {
                backButton
                detail
            } else {
                results
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search a city", text: $query)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
        )
    }

    @ViewBuilder
    private var results: some View {
        switch phase {
        case .idle:
            hint("Type to search cities.")
        case .searching:
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        case .empty:
            hint("No cities matched.")
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.callout)
                .foregroundStyle(.secondary)
        case .results(let places):
            VStack(spacing: 0) {
                ForEach(places) { place in
                    Button { onSelect(place) } label: {
                        HStack {
                            Text(place.displayName)
                                .font(.callout)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if place.id != places.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            Label("Back to results", systemImage: "chevron.left")
                .font(.callout)
                .foregroundStyle(accent)
        }
        .buttonStyle(.plain)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
    }
}
