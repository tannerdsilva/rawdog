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
		
		@Test("RAW_ed25519 :: sign / verify round-trip with tamper detection")
		func testSignVerifyRoundTrip() throws {
			let randomPrivateKey = try generateSecureRandomBytes(count:32).withUnsafeBytes { buff in
				return MemoryGuarded<RAW_dh25519.PrivateKey>(RAW_decode:buff)!
			}
			let keypair = try generateKeys(secretKey:randomPrivateKey)
			let message:[UInt8] = [0x00, 0x01, 0x02, 0x03, 0xDE, 0xAD, 0xBE, 0xEF]
			var signature = [UInt8](repeating:0, count:64)

			// free-function sign / verify
			message.withUnsafeBufferPointer { msgBuf in
				signature.withUnsafeMutableBufferPointer { sigBuf in
					sign(to:sigBuf, privateKey:keypair.1, message:msgBuf)
				}
				signature.withUnsafeBufferPointer { sigBuf in
					#expect(verify(signature:sigBuf, publicKey:keypair.0, message:msgBuf) == true)
				}
			}

			// reusable verification context
			let verifyCtx = VerificationContext(publicKey:keypair.0)
			message.withUnsafeBufferPointer { msgBuf in
				signature.withUnsafeBufferPointer { sigBuf in
					#expect(verifyCtx.verify(signature:sigBuf, message:msgBuf) == true)
				}
			}

			// tampered signature must fail
			signature[0] ^= 0xFF
			message.withUnsafeBufferPointer { msgBuf in
				signature.withUnsafeBufferPointer { sigBuf in
					#expect(verify(signature:sigBuf, publicKey:keypair.0, message:msgBuf) == false)
				}
			}
		}
	}
}
