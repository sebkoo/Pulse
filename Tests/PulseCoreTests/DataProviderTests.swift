import XCTest
@testable import PulseCore

/// Exercises the offline-first contract end to end with a scripted provider —
/// no network anywhere near these tests.
final class DataProviderTests: XCTestCase {
    struct StubProvider: DataProvider {
        let id = "stub"
        let title = "Stub"
        let result: Result<String, StubError>

        func fetch() async throws -> String {
            try result.get()
        }
    }

    enum StubError: Error, Equatable { case offline }

    private func makeCache() -> PayloadCache<String> {
        PayloadCache<String>(
            key: "test-\(UUID().uuidString)",
            directory: FileManager.default.temporaryDirectory
        )
    }

    func testFreshFetchReturnsAndCaches() async throws {
        let cache = makeCache()
        let provider = StubProvider(result: .success("sunny"))

        let result = try await provider.fetchCachingLastGood(cache: cache, now: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(result.payload, "sunny")
        XCTAssertFalse(result.isStale)
        let entry = await cache.load()
        XCTAssertEqual(entry?.payload, "sunny")   // cached for next time
        await cache.clear()
    }

    func testNetworkFailureFallsBackToCacheMarkedStale() async throws {
        let cache = makeCache()
        try await cache.save("yesterday", fetchedAt: Date(timeIntervalSince1970: 100))
        let provider = StubProvider(result: .failure(.offline))

        let result = try await provider.fetchCachingLastGood(cache: cache, now: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(result.payload, "yesterday")
        XCTAssertTrue(result.isStale)                                   // honesty surfaced
        XCTAssertEqual(result.age(now: Date(timeIntervalSince1970: 160)), 60)
        await cache.clear()
    }

    func testFailureWithEmptyCacheThrows() async {
        let cache = makeCache()
        let provider = StubProvider(result: .failure(.offline))

        do {
            _ = try await provider.fetchCachingLastGood(cache: cache)
            XCTFail("expected an error when there is neither fresh nor cached data")
        } catch {
            XCTAssertEqual(error as? StubError, .offline)
        }
    }

    func testCorruptedCacheIsAMissNeverACrash() async throws {
        let dir = FileManager.default.temporaryDirectory
        let key = "corrupt-\(UUID().uuidString)"
        let cache = PayloadCache<String>(key: key, directory: dir)
        try Data("garbage".utf8).write(to: dir.appendingPathComponent("pulse-cache-\(key).json"))

        let entry = await cache.load()
        XCTAssertNil(entry)
    }
}
