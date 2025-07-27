// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
@testable import __crawdog_curve25519_tests

extension rawdog_tests {
	@Suite("__crawdog_curve25519",
		.serialized
	)
	struct Ed25519Tests {
		@Test("__crawdog_curve25519 :: core")
		func testED25519Suite() {
			#expect(allTestsRelatedTo25519() == 0)
		}
	}
}