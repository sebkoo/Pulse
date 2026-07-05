import XCTest
@testable import PulseProviders

final class USGSQuakesProviderTests: XCTestCase {
    func testParsesSortsAndDropsJunk() async throws {
        let session = StubURLProtocol.makeSession(body: #"""
        {"features":[
          {"id":"q-old","properties":{"mag":5.1,"place":"southern Alaska","time":1000000}},
          {"id":"q-new","properties":{"mag":4.6,"place":"central California","time":2000000}},
          {"id":"","properties":{"mag":6.0,"place":"no id","time":3000000}},
          {"id":"q-no-mag","properties":{"place":"missing magnitude","time":3000000}},
          {"id":"q-no-place","properties":{"mag":4.9,"time":3000000}}
        ]}
        """#)
        let provider = USGSQuakesProvider(session: session)

        let quakes = try await provider.fetch()

        XCTAssertEqual(quakes.map(\.id), ["q-new", "q-old"])       // junk dropped, newest first
        XCTAssertEqual(quakes[0].magnitude, 4.6)
        XCTAssertEqual(quakes[1].time, Date(timeIntervalSince1970: 1000)) // ms -> Date
    }

    func testQuietPlanetIsAnEmptyListNotAnError() async throws {
        let session = StubURLProtocol.makeSession(body: #"{"features":[]}"#)
        let provider = USGSQuakesProvider(session: session)

        let quakes = try await provider.fetch()

        XCTAssertTrue(quakes.isEmpty)
    }

    func testMissingFeaturesThrowsUnusablePayload() async {
        let session = StubURLProtocol.makeSession(body: "{}")
        let provider = USGSQuakesProvider(session: session)

        do {
            _ = try await provider.fetch()
            XCTFail("expected unusablePayload")
        } catch {
            XCTAssertEqual(error as? USGSQuakesProvider.ProviderError, .unusablePayload)
        }
    }

    func testHTTPFailureThrowsTypedError() async {
        let session = StubURLProtocol.makeSession(status: 500, body: "")
        let provider = USGSQuakesProvider(session: session)

        do {
            _ = try await provider.fetch()
            XCTFail("expected badResponse")
        } catch {
            XCTAssertEqual(error as? USGSQuakesProvider.ProviderError, .badResponse(status: 500))
        }
    }
}
