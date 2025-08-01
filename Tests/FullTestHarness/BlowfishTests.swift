// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
@testable import __crawdog_crypt_blowfish_tests
import RAW_hex

extension rawdog_tests {
	@Suite("__crawdog_crypt_blowfish",
		.serialized
	)
	struct TestBlowfishHashing {
		@Test("__crawdog_crypt_blowfish :: core")
		func testMainFunction() {
			#expect(__crawdog_crypt_test_swiftshim() == 0)
		}
	}
}