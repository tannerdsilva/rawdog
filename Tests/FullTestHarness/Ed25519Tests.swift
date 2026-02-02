// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import RAW
@testable import __crawdog_curve25519_tests
@testable import RAW_ed25519

extension rawdog_tests {
	@Suite("__crawdog_curve25519",
		.serialized
	)
	struct Curve25519Tests {
		@Test("__crawdog_curve25519 :: core")
		func testCurve25519Suite() {
			#expect(allTestsRelatedTo25519() == 0)
		}
	}
	
	@Suite(
		"__crawdog_ed25519",
		.serialized
	)
	struct ED25519Tests {
	
		@RAW_staticbuff(bytes:32)
		struct My32Bytes:Sendable {}
	
		@Test("__crawdog_ed25519 :: blinding context :: lifecycle test")
		func testBlindingContextLifecycle() throws {
			let randomSource = try generateSecureRandomBytes(count:64)
			try randomSource.RAW_access { randomSourceBufferPointer in
				var newBlindingContext:BlindingContext? = try BlindingContext(randomSource:randomSourceBufferPointer)
				#expect(newBlindingContext!.storage != nil)
				newBlindingContext = nil
			}
		}
	}
}