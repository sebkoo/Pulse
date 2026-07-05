import XCTest
@testable import PulseCore

final class BrandConfigTests: XCTestCase {
    func testDecodesAFullBrandFile() {
        let json = ##"{"appName":"Acme Ops","accentColorHex":"#FF5500","modules":["Weather"," earthquakes ",""]}"##
        let config = BrandConfig.load(from: Data(json.utf8))

        XCTAssertEqual(config.appName, "Acme Ops")
        XCTAssertEqual(config.accentColorHex, "#FF5500")
        XCTAssertEqual(config.modules, ["weather", "earthquakes"]) // normalized, empties dropped
    }

    func testPartialConfigFallsBackPerField() {
        let config = BrandConfig.load(from: Data(#"{"appName":"Solo"}"#.utf8))

        XCTAssertEqual(config.appName, "Solo")
        XCTAssertEqual(config.accentColorHex, "#1F3A5F")            // default
        XCTAssertEqual(config.modules, ["weather", "earthquakes"]) // default
    }

    func testBrokenOrMissingConfigFallsBackToDefaults() {
        XCTAssertEqual(BrandConfig.load(from: Data("not json".utf8)).appName, "Pulse")
        XCTAssertEqual(BrandConfig.load(from: nil), BrandConfig())
    }
}
