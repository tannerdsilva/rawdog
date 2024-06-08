// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
@testable import __crawdog_curve25519_tests

class Ed25519Tests: XCTestCase {
	// Add your test methods here
	func testED25519Suite() {
		guard allTestsRelatedTo25519() == 0 else {
			XCTFail("Failed to run all tests related to 25519")
			return
		}
	}
}