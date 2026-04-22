//
//  KyberTests 2.swift
//  rawdog
//
//  Created by Brock Wyma on 4/21/26.
//


// copyright (c) tanner silva 2024. all rights reserved.

import Testing
@testable import RAW_dilithium
import RAW

@RAW_staticbuff(bytes: 32)
fileprivate struct Message: Sendable {}

extension rawdog_tests {
	@Suite("Dilithium Tests")
	struct DilithiumTests {
		// Add your test methods here
		@Test func testDilithiumSigning() throws {
			let (pubKey, privKey) = try RAW_dilithium.generateDilithiumKeyPair()
			let exampleMessage = try generateSecureRandomBytes(as: Message.self)
			
			let context: [UInt8] = [1, 2, 3, 4]
			var signature = Signature(RAW_staticbuff: Signature.RAW_staticbuff_zeroed())
			
			signature.RAW_access_mutating { sigPtr in
				context.withUnsafeBufferPointer { buffer in
					let blindingContext = RAW_dilithium.BlindingContext(context: buffer)
					exampleMessage.RAW_access { messagePtr in
						blindingContext.sign(to: sigPtr.baseAddress!, privateKey: privKey, message: messagePtr)
					}
				}
			}
			
			signature.RAW_access { sigPtr in
				context.withUnsafeBufferPointer { buffer in
					let verificationContext = RAW_dilithium.VerificationContext(context: buffer)
					exampleMessage.RAW_access { messagePtr in
						let isVerified = verificationContext.verify(signature: sigPtr, message: messagePtr, publicKey: pubKey)
						#expect(isVerified)
					}
				}
			}
		}
	}
}
