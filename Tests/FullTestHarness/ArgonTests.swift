// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
import __crawdog_argon2
import __crawdog_argon2_tests

class Argon2Tests: XCTestCase {
	func testArgon2BuiltinTests() throws {
		XCTAssertEqual(__crawdog_argon2testf(), 0)
	}
}