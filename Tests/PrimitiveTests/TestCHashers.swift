// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import XCTest
@testable import __crawdog_hashing_tests

class CHasherTests: XCTestCase {
	// Add your test methods here
	func testCHashers() {
		guard __crawdog_testHashing() == true else {
			fatalError("c hashers failed")
		}
	}
}