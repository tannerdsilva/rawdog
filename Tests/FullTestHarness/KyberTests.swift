// copyright (c) tanner silva 2024. all rights reserved.

import Testing
@testable import RAW_kyber

extension rawdog_tests {
	@Suite("Kyber Tests")
	struct KyberTests {
		// Add your test methods here
		@Test func testKyberKeys() throws {
			let (pubKey, privKey) = try RAW_kyber.generateKyberKeyPair()
			
			let (cipherText, sharedSecretA) = RAW_kyber.kyberEncode(publicKey: pubKey)
			let sharedSecretB = RAW_kyber.kyberDecode(cipherText: cipherText, privateKey: privKey)
			
			#expect(sharedSecretA == sharedSecretB)
		}
	}
}
