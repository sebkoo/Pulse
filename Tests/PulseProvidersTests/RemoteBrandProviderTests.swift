import XCTest
@testable import PulseProviders
import PulseCore

final class RemoteBrandProviderTests: XCTestCase {
    private let base = URL(string: "https://brands.example.com")!

    func testDecodesBrandFromService() async {
        let session = StubURLProtocol.makeSession(body: #"""
        {"appName":"Acme Field Ops","accentColorHex":"#E05910","modules":["earthquakes","weather"]}
        """#)
        let provider = RemoteBrandProvider(baseURL: base, session: session)

        let config = await provider.brand(id: "acme")

        XCTAssertEqual(config.appName, "Acme Field Ops")
        XCTAssertEqual(config.modules, ["earthquakes", "weather"])
    }

    func testFallsBackToDefaultOnHTTPError() async {
        let session = StubURLProtocol.makeSession(status: 500, body: "")
        let provider = RemoteBrandProvider(baseURL: base, session: session)

        let config = await provider.brand(id: "acme")

        XCTAssertEqual(config, BrandConfig())
    }

    func testFallsBackToTheGivenDefaultOnGarbage() async {
        let session = StubURLProtocol.makeSession(body: "not json at all")
        let provider = RemoteBrandProvider(baseURL: base, session: session)

        let bundled = BrandConfig(appName: "Bundled", accentColorHex: "#123456", modules: ["weather"])
        let config = await provider.brand(id: "acme", fallback: bundled)

        XCTAssertEqual(config, bundled)
    }
}
