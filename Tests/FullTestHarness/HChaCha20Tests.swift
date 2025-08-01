import Testing
@testable import __crawdog_hchacha20_tests

extension rawdog_tests {
	@Suite("__crawdog_hchacha20",
		.serialized
	)
	struct HChaCha20Tests {
		@Test("__crawdog_hchacha20 :: core")
		func testHChaCha20() {
			#expect(tv_hchacha20() == 0)
		}
	}
}