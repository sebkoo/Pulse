import XCTVapor
@testable import PulseServer
import PulseCore

final class BrandRoutesTests: XCTestCase {
    private func makeApp() async throws -> Application {
        let app = try await Application.make(.testing)
        try configure(app)
        return app
    }

    func testHealthReturnsOK() async throws {
        let app = try await makeApp()
        try await app.test(.GET, "health") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "ok")
        }
        try await app.asyncShutdown()
    }

    func testKnownBrandReturnsItsConfig() async throws {
        let app = try await makeApp()
        try await app.test(.GET, "brands/acme") { res in
            XCTAssertEqual(res.status, .ok)
            let config = try res.content.decode(BrandConfig.self)
            XCTAssertEqual(config.appName, "Acme Field Ops")
            XCTAssertEqual(config.modules, ["earthquakes", "weather"])
        }
        try await app.asyncShutdown()
    }

    func testBrandIdIsCaseInsensitive() async throws {
        let app = try await makeApp()
        try await app.test(.GET, "brands/ACME") { res in
            XCTAssertEqual(res.status, .ok)
            let config = try res.content.decode(BrandConfig.self)
            XCTAssertEqual(config.appName, "Acme Field Ops")
        }
        try await app.asyncShutdown()
    }

    func testUnknownBrandReturns404() async throws {
        let app = try await makeApp()
        try await app.test(.GET, "brands/nope") { res in
            XCTAssertEqual(res.status, .notFound)
        }
        try await app.asyncShutdown()
    }
}
