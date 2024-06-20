import XCTest
@testable import __crawdog_hchacha20_tests

class HChaCha20Tests: XCTestCase {
	func testHChaCha20() {
		XCTAssertEqual(tv_hchacha20(), 0)
	}
}