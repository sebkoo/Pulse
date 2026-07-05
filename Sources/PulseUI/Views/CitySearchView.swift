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
        VStack(alignment: .leading, spacing: 14) {
            searchField
            if let place = selected {
                backButton
                WeatherResultView(place: place, accent: accent)
                    .id(place.id)
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
            TextField("Search a city", text: $model.query)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !model.query.isEmpty {
                Button {
                    model.query = ""
                    selected = nil
                } label: {
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
        switch model.phase {
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
                    Button { selected = place } label: {
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
        Button { selected = nil } label: {
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
