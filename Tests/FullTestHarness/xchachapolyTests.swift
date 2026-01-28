// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
@testable import __crawdog_xchachapoly
@testable import RAW_xchachapoly
import struct RAW_chachapoly.Key32
import struct RAW_chachapoly.Tag
import __crawdog_hchacha20
import RAW
import RAW_hex

extension rawdog_tests {
	@Suite("__crawdog_xchachapoly_tests")
	struct xchachapolyTests {
		@Test func testVectorXChaChaPoly() throws {
			let plaintextData = try RAW_hex.decode("4c616469657320616e642047656e746c656d656e206f662074686520636c617373206f66202739393a204966204920636f756c64206f6666657220796f75206f6e6c79206f6e652074697020666f7220746865206675747572652c2073756e73637265656e20776f756c642062652069742e")
			let key = Key(RAW_staticbuff:try RAW_hex.decode("808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f"))
			let nonce = RAW_xchachapoly.Nonce(RAW_staticbuff:try RAW_hex.decode("404142434445464748494a4b4c4d4e4f5051525354555657"))
			let aad = try RAW_hex.decode("50515253c0c1c2c3c4c5c6c7")

			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:plaintextData.count)
			defer {
				buffer.deallocate()
			}
			let returnedTag = try plaintextData.RAW_access { ptPtr in
				return try aad.RAW_access { aadPtr in
					var context = RAW_xchachapoly.Context(key:key)
					return try context.encrypt(nonce:nonce, associatedData:aadPtr, inputData:ptPtr, output:buffer.baseAddress!)
				}
			}
			let expectedTag = RAW_chachapoly.Tag(RAW_staticbuff:try RAW_hex.decode("c0875924c1c7987947deafd8780acf49"))
			let expectedCiphertext = try RAW_hex.decode("bd6d179d3e83d43b9576579493c0e939572a1700252bfaccbed2902c21396cbb731c7f1b0b4aa6440bf3a82f4eda7e39ae64c6708c54c216cb96b72e1213b4522f8c9ba40db5d945b11b69b982c1bb9e3f3fac2bc369488f76b2383565d3fff921f9664c97637da9768812f615c68b13b52e")
			let outputCipher = [UInt8](buffer)
			#expect(returnedTag == expectedTag)
			#expect(outputCipher == expectedCiphertext)
		}
		@Test func testXChachaPolyEncryptDecryptRandomData() throws {
			for _ in 0..<64 {
				var testKey = try generateSecureRandomBytes(as:Key32.self)
				var testNonce = try generateSecureRandomBytes(as:RAW_xchachapoly.Nonce.self)

				var context = RAW_xchachapoly.Context(key:testKey)
				var plaintext = Array<UInt8>("hello this is some plain text - lets see if we can encrypt it".utf8)
				let byteBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:plaintext.count)
				defer {
					byteBuffer.deallocate()
				}
				let tag = try plaintext.RAW_access { ptPtr in
					return try [UInt8]().RAW_access { adBuff in
						return try context.encrypt(nonce:testNonce, associatedData:adBuff, inputData:ptPtr, output:byteBuffer.baseAddress!)
					}
				}
				let decryptedBytes = [UInt8](byteBuffer)

				let reverseText = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:decryptedBytes.count)
				defer {
					reverseText.deallocate()
				}
				try plaintext.RAW_access { ptPtr in
					try [UInt8]().RAW_access { adBuff in
						try context.decrypt(tag:tag, nonce:testNonce, associatedData:adBuff, inputData:UnsafeBufferPointer<UInt8>(byteBuffer), output:reverseText.baseAddress!)
					}
				}
				let reverseBytes = [UInt8](reverseText)

				#expect(plaintext == reverseBytes)
			}
		}
	}
}