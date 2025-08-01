// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import __crawdog_argon2
import __crawdog_argon2_tests

extension rawdog_tests {
	@Suite("RAW_argon2",
		.serialized
	)
	struct Argon2Tests {
		@Test("RAW_argon2 :: core")
		func testArgon2BuiltinTests() throws {
			#expect(__crawdog_argon2testf() == 0)
		}
	}
}