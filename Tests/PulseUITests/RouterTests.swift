import XCTest
@testable import PulseUI

@MainActor
final class RouterTests: XCTestCase {
    func testPushAppendsInOrder() {
        let router = Router()

        router.push(.weatherSearch)
        router.push(.quakes)

        XCTAssertEqual(router.path, [.weatherSearch, .quakes])
    }

    func testPopRemovesTheLastRoute() {
        let router = Router()
        router.push(.weatherSearch)
        router.push(.quakes)

        router.pop()

        XCTAssertEqual(router.path, [.weatherSearch])
    }

    func testPopOnEmptyPathIsSafe() {
        let router = Router()

        router.pop()

        XCTAssertEqual(router.path, [])
    }

    func testPopToRootClearsEverything() {
        let router = Router()
        router.push(.weatherSearch)
        router.push(.quakes)

        router.popToRoot()

        XCTAssertEqual(router.path, [])
    }
}
