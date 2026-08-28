// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import RAW
import RAW_dh25519
@testable import __crawdog_curve25519_tests
@testable import RAW_ed25519

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
	
	@Suite("__crawdog_ed25519",
		.serialized
	)
	struct ED25519Tests {
	
		@Test("__crawdog_ed25519 :: blinding context :: lifecycle test")
		func testBlindingContextLifecycle() throws {
			let randomSource = try generateSecureRandomBytes(count:64)
			// the blinding context is ~Copyable: keep it scoped to a single expression
			// and lift only its (copyable) storage pointer across the assert boundary.
			let storagePointer = try randomSource.RAW_access_immutable { buffer -> UnsafeMutableRawPointer in
				let context = BlindingContext(randomSource:buffer)
				return context.storage
			}
			#expect(storagePointer != nil)
		}
		
		@Test("RAW_ed25519 :: VerificationContext :: lifecycle test")
		func testVerificationContext() throws {
			let randomPrivateKey = try generateSecureRandomBytes(count:32).withUnsafeBytes { buff in
				return MemoryGuarded<RAW_dh25519.PrivateKey>(RAW_decode:buff)!
			}
			let keypair = try generateKeys(secretKey:randomPrivateKey)
			let storagePointer = VerificationContext(publicKey:keypair.0).storage
			#expect(storagePointer != nil)
		}
	}
}
