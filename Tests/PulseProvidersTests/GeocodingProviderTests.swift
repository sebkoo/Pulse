import XCTest
@testable import PulseProviders

final class GeocodingProviderTests: XCTestCase {
    func testParsesAndNormalizesResults() async throws {
        let session = StubURLProtocol.makeSession(body: #"""
        {"results":[
          {"id":1,"name":"Ridgecrest","admin1":"California","country":"United States",
           "latitude":35.62,"longitude":-117.67},
          {"id":2,"name":"Paris","admin1":"Île-de-France","country":"France",
           "latitude":48.85,"longitude":2.35}
        ]}
        """#)
        let provider = GeocodingProvider(session: session)

        let places = try await provider.search("query")

        XCTAssertEqual(places.count, 2)
        XCTAssertEqual(places[0].displayName, "Ridgecrest, California, United States")
        XCTAssertEqual(places[0].latitude, 35.62)
        XCTAssertEqual(places[1].name, "Paris")
    }

    func testResultsMissingEssentialsAreDropped() async throws {
        let session = StubURLProtocol.makeSession(body: #"""
        {"results":[
          {"id":1,"name":"Valid","latitude":10.0,"longitude":20.0},
          {"id":2,"name":"No coordinates"},
          {"id":3,"latitude":1.0,"longitude":2.0}
        ]}
        """#)
        let provider = GeocodingProvider(session: session)

        let places = try await provider.search("query")

        XCTAssertEqual(places.map(\.name), ["Valid"])
    }

    func testNoMatchesIsAnEmptyListNotAnError() async throws {
        let session = StubURLProtocol.makeSession(body: "{}")
        let provider = GeocodingProvider(session: session)

        let places = try await provider.search("nowhere")

        XCTAssertEqual(places, [])
    }

    func testEmptyQueryShortCircuits() async throws {
        let session = StubURLProtocol.makeSession(status: 500, body: "")
        let provider = GeocodingProvider(session: session)

        // Never reaches the network, so the 500 stub is irrelevant.
        let places = try await provider.search("   ")

        XCTAssertEqual(places, [])
    }

    func testHTTPFailureThrowsTypedError() async {
        let session = StubURLProtocol.makeSession(status: 503, body: "")
        let provider = GeocodingProvider(session: session)

        do {
            _ = try await provider.search("query")
            XCTFail("expected badResponse")
        } catch {
            XCTAssertEqual(error as? GeocodingProvider.ProviderError, .badResponse(status: 503))
        }
    }
}
