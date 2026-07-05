import XCTest
import PulseCore
@testable import PulseUI

/// The module view model's three phases, exercised with a scripted provider —
/// no network, no views.
final class ModuleModelTests: XCTestCase {
    struct StubProvider: DataProvider {
        let id = "stub"
        let title = "Stub"
        let result: Result<String, StubError>
        func fetch() async throws -> String { try result.get() }
    }

    enum StubError: Error { case offline }

    private func makeCache() -> PayloadCache<String> {
        PayloadCache<String>(
            key: "ui-test-\(UUID().uuidString)",
            directory: FileManager.default.temporaryDirectory
        )
    }

    @MainActor
    func testLoadReachesLoadedFresh() async {
        let model = ModuleModel(provider: StubProvider(result: .success("sunny")), cache: makeCache())
        XCTAssertEqual(model.phase, .loading)

        await model.load(now: Date(timeIntervalSince1970: 50))

        guard case .loaded(let result) = model.phase else { return XCTFail("expected loaded") }
        XCTAssertEqual(result.payload, "sunny")
        XCTAssertFalse(result.isStale)
    }

    @MainActor
    func testFailureWithCacheLoadsStale() async throws {
        let cache = makeCache()
        try await cache.save("yesterday", fetchedAt: Date(timeIntervalSince1970: 10))
        let model = ModuleModel(provider: StubProvider(result: .failure(.offline)), cache: cache)

        await model.load()

        guard case .loaded(let result) = model.phase else { return XCTFail("expected stale loaded") }
        XCTAssertEqual(result.payload, "yesterday")
        XCTAssertTrue(result.isStale)
        await cache.clear()
    }

    @MainActor
    func testFailureWithoutCacheFails() async {
        let model = ModuleModel(provider: StubProvider(result: .failure(.offline)), cache: makeCache())

        await model.load()

        guard case .failed(let message) = model.phase else { return XCTFail("expected failed") }
        XCTAssertTrue(message.contains("stub"))
    }
}
