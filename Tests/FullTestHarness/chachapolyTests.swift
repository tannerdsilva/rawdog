// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import __crawdog_chachapoly_tests

extension rawdog_tests {
	@Suite("__crawdog_chachapoly_tests",
		.serialized
	)
	struct chachapolyTests {
		@Test("__crawdog_chachapoly_tests :: core")
		func testChachaPoly() throws {
			#expect(__crawdog_chachapoly_test_rfc7539() == 0)
			#expect(__crawdog_chachapoly_test_auth_only() == 0)
		}
	}
}