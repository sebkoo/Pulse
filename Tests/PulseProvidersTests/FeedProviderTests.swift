import XCTest
@testable import PulseProviders
import PulseCore

final class FeedProviderTests: XCTestCase {
    private let base = URL(string: "https://bff.example.com")!

    func testDecodesTheAggregatedFeedInOrder() async throws {
        let session = StubURLProtocol.makeSession(body: #"""
        {
          "brand": {"appName":"Acme Field Ops","accentColorHex":"#E05910","modules":["earthquakes","weather"]},
          "modules": [
            {"id":"earthquakes","quakes":[
              {"id":"s1","magnitude":6.1,"place":"Sand Point, Alaska","time":"2026-07-05T00:00:00.000Z"}
            ]},
            {"id":"weather","weather":{"temperature":27.4,"unit":"°C","windSpeed":9,"conditionCode":2,"condition":"Partly cloudy"}}
          ]
        }
        """#)
        let provider = FeedProvider(baseURL: base, session: session)

        let feed = try await provider.feed(brandId: "acme")

        XCTAssertEqual(feed.brand.appName, "Acme Field Ops")
        XCTAssertEqual(feed.modules.map(\.id), ["earthquakes", "weather"])
        XCTAssertEqual(feed.modules[0].quakes?.first?.magnitude, 6.1)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let expectedTime = utc.date(from: DateComponents(year: 2026, month: 7, day: 5))!
        XCTAssertEqual(feed.modules[0].quakes?.first?.time, expectedTime)
        XCTAssertEqual(feed.modules[1].weather?.temperature, 27.4)
        XCTAssertNil(feed.modules[1].quakes)
    }

    func testHTTPFailureThrowsTypedError() async {
        let session = StubURLProtocol.makeSession(status: 404, body: "")
        let provider = FeedProvider(baseURL: base, session: session)

        do {
            _ = try await provider.feed(brandId: "nope")
            XCTFail("expected badResponse")
        } catch {
            XCTAssertEqual(error as? FeedProvider.ProviderError, .badResponse(status: 404))
        }
    }
}
