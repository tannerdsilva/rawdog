import XCTest
@testable import ced25519_tests

class Ed25519Tests: XCTestCase {
	// Add your test methods here
	func testED25519Suite() {
		guard _ED25519_TEST_MAINF() == 0 else {
			XCTFail("Ed25519 test failed")
			return
		}
		guard _ED25519_TEST_INTERNALS() == 0 else {
			XCTFail("Ed25519 test failed")
			return
		}
	}
}