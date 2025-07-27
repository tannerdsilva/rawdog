// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import Testing
@testable import __crawdog_hashing_tests

extension rawdog_tests {
	@Suite("__crawdog_hashing_tests")
	struct CHasherTests {
		// Add your test methods here
		func testCHashers() {
			guard __crawdog_testHashing() == true else {
				fatalError("c hashers failed")
			}
		}
	}
}