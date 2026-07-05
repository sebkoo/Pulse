import XCTest
@testable import PulseUI
import PulseProviders

@MainActor
final class CitySearchModelTests: XCTestCase {
    /// The whole reason Combine is here: a burst of keystrokes must collapse
    /// into a single search for the final term.
    func testDebounceCollapsesRapidKeystrokes() async throws {
        let recorder = QueryRecorder()
        let model = CitySearchModel(debounce: .milliseconds(50)) { query in
            await recorder.record(query)
            return [place(named: query)]
        }

        model.query = "S"
        model.query = "Sa"
        model.query = "San"

        try await Task.sleep(for: .milliseconds(300))

        let recorded = await recorder.queries()
        XCTAssertEqual(recorded, ["San"], "rapid keystrokes should debounce to one search")
        XCTAssertEqual(model.phase, .results([place(named: "San")]))
    }

    func testEmptyResultsBecomeTheEmptyPhase() async throws {
        let model = CitySearchModel(debounce: .milliseconds(50)) { _ in [] }

        model.query = "Atlantis"
        try await Task.sleep(for: .milliseconds(250))

        XCTAssertEqual(model.phase, .empty)
    }

    func testFailuresSurfaceAsFailedPhase() async throws {
        struct Boom: Error {}
        let model = CitySearchModel(debounce: .milliseconds(50)) { _ in throw Boom() }

        model.query = "anywhere"
        try await Task.sleep(for: .milliseconds(250))

        guard case .failed = model.phase else {
            return XCTFail("expected failed, got \(model.phase)")
        }
    }
}

/// Non-isolated so the `@Sendable` search closure can build fixtures off the
/// main actor.
private func place(named name: String) -> GeocodedPlace {
    GeocodedPlace(id: 1, name: name, admin1: nil, country: nil, latitude: 0, longitude: 0)
}

/// Records the queries the search closure actually received, across actors.
private actor QueryRecorder {
    private var recorded: [String] = []
    func record(_ query: String) { recorded.append(query) }
    func queries() -> [String] { recorded }
}
