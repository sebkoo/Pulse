import XCTest
@testable import PulseProviders

final class OpenMeteoProviderTests: XCTestCase {
    func testParsesACurrentWeatherPayload() async throws {
        let session = StubURLProtocol.makeSession(body: #"""
        {"current":{"temperature_2m":31.4,"weather_code":95,"wind_speed_10m":12.3},
         "current_units":{"temperature_2m":"°C"}}
        """#)
        let provider = OpenMeteoProvider(session: session)

        let snapshot = try await provider.fetch()

        XCTAssertEqual(snapshot.temperature, 31.4)
        XCTAssertEqual(snapshot.unit, "°C")
        XCTAssertEqual(snapshot.windSpeed, 12.3)
        XCTAssertEqual(snapshot.condition, "Thunderstorm")
    }

    func testMissingFieldsDegradeGracefully() async throws {
        let session = StubURLProtocol.makeSession(body: #"{"current":{"temperature_2m":20.0}}"#)
        let provider = OpenMeteoProvider(session: session)

        let snapshot = try await provider.fetch()

        XCTAssertEqual(snapshot.unit, "°C")            // default unit
        XCTAssertEqual(snapshot.windSpeed, 0)          // default wind
        XCTAssertEqual(snapshot.condition, "Unknown")  // unknown code degrades
    }

    func testUnusablePayloadThrows() async {
        let session = StubURLProtocol.makeSession(body: "{}")
        let provider = OpenMeteoProvider(session: session)

        do {
            _ = try await provider.fetch()
            XCTFail("expected unusablePayload")
        } catch {
            XCTAssertEqual(error as? OpenMeteoProvider.ProviderError, .unusablePayload)
        }
    }

    func testHTTPFailureThrowsTypedError() async {
        let session = StubURLProtocol.makeSession(status: 503, body: "")
        let provider = OpenMeteoProvider(session: session)

        do {
            _ = try await provider.fetch()
            XCTFail("expected badResponse")
        } catch {
            XCTAssertEqual(error as? OpenMeteoProvider.ProviderError, .badResponse(status: 503))
        }
    }
}
