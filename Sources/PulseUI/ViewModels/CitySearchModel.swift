import Combine
import Foundation
import PulseProviders

/// Debounced city search — the one place Pulse reaches for Combine.
///
/// Keystrokes are a *stream*, and `debounce` is exactly the operator for
/// collapsing a burst of edits into a single search. Everywhere else the app
/// models *state*, which is Observation's job (`ModuleModel`). Picking the
/// right tool for each — state vs. stream — is the point, not using one
/// framework everywhere.
@MainActor
final class CitySearchModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case searching
        case results([GeocodedPlace])
        case empty
        case failed(String)
    }

    @Published var query: String = ""
    @Published private(set) var phase: Phase = .idle

    private let search: @Sendable (String) async throws -> [GeocodedPlace]
    private var cancellables: Set<AnyCancellable> = []
    private var inFlight: Task<Void, Never>?

    /// `debounce` is injectable so tests can shrink the quiet window; `search`
    /// is injectable so tests never touch the network.
    init(
        debounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300),
        search: @escaping @Sendable (String) async throws -> [GeocodedPlace]
    ) {
        self.search = search
        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: debounce, scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                Task { @MainActor in self?.run(query) }
            }
            .store(in: &cancellables)
    }

    private func run(_ query: String) {
        inFlight?.cancel()
        guard !query.isEmpty else {
            phase = .idle
            return
        }
        phase = .searching
        inFlight = Task { [weak self, search] in
            do {
                let places = try await search(query)
                guard !Task.isCancelled else { return }
                self?.phase = places.isEmpty ? .empty : .results(places)
            } catch {
                guard !Task.isCancelled else { return }
                self?.phase = .failed("Couldn't search cities. Check your connection.")
            }
        }
    }
}
