// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import RAW
import RAW_chachapoly
import RAW_xchachapoly

extension rawdog_tests {
	// these suites exist because the AEAD decrypt path's MAC failure surface
	// (``RAW_chachapoly.InvalidMACError``) was only proven at the C layer; the Swift
	// throwing wrappers were never exercised against tampered inputs.

	@Suite("chachapoly tamper detection")
	struct ChaChaPolyTamperTests {

		private func zeroNonce() -> RAW_chachapoly.Nonce {
			[UInt8](repeating: 0, count: 12).withUnsafeBytes { RAW_chachapoly.Nonce(RAW_decode: $0)! }
		}

		private func zeroKey() -> RAW_chachapoly.Key32 {
			[UInt8](repeating: 0, count: 32).withUnsafeBytes { RAW_chachapoly.Key32(RAW_decode: $0)! }
		}

		private func encryptMessage() throws -> (ciphertext: [UInt8], tag: RAW_chachapoly.Tag) {
			var context = RAW_chachapoly.Context(key: zeroKey())
			let message = Array("attack at dawn".utf8)
			let ad = [UInt8]([0x11, 0x22, 0x33])
			let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: message.count)
			defer {
				output.deallocate()
			}
			let tag = try message.withUnsafeBufferPointer { msg in
				try ad.withUnsafeBufferPointer { aad in
					try context.encrypt(nonce: zeroNonce(), associatedData: aad, inputData: msg, output: output.baseAddress!)
				}
			}
			return ([UInt8](output), tag)
		}

		@Test("decrypt rejects tampered ciphertext")
		func testCiphertextTamper() throws {
			let (ciphertext, tag) = try encryptMessage()
			var tampered = ciphertext
			tampered[0] ^= 0x01
			let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: tampered.count)
			defer {
				output.deallocate()
			}
			#expect(throws: RAW_chachapoly.InvalidMACError.self) {
				try tampered.withUnsafeBufferPointer { buf in
					let ad = [UInt8]([0x11, 0x22, 0x33])
					try ad.withUnsafeBufferPointer { aad in
						var context = RAW_chachapoly.Context(key: zeroKey())
						try context.decrypt(tag: tag, nonce: zeroNonce(), associatedData: aad, inputData: buf, output: output.baseAddress!)
					}
				}
			}
		}

		@Test("decrypt rejects tampered tag")
		func testTagTamper() throws {
			let (ciphertext, tag) = try encryptMessage()
			var badTag = tag
			badTag.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { $0[0] ^= 0x01 }
			let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: ciphertext.count)
			defer {
				output.deallocate()
			}
			#expect(throws: RAW_chachapoly.InvalidMACError.self) {
				try ciphertext.withUnsafeBufferPointer { buf in
					let ad = [UInt8]([0x11, 0x22, 0x33])
					try ad.withUnsafeBufferPointer { aad in
						var context = RAW_chachapoly.Context(key: zeroKey())
						try context.decrypt(tag: badTag, nonce: zeroNonce(), associatedData: aad, inputData: buf, output: output.baseAddress!)
					}
				}
			}
		}

		@Test("decrypt rejects tampered associated data")
		func testDataTamper() throws {
			let (ciphertext, tag) = try encryptMessage()
			let badAD = [UInt8]([0x11, 0x22, 0x34])
			let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: ciphertext.count)
			defer {
				output.deallocate()
			}
			#expect(throws: RAW_chachapoly.InvalidMACError.self) {
				try ciphertext.withUnsafeBufferPointer { buf in
					try badAD.withUnsafeBufferPointer { aad in
						var context = RAW_chachapoly.Context(key: zeroKey())
						try context.decrypt(tag: tag, nonce: zeroNonce(), associatedData: aad, inputData: buf, output: output.baseAddress!)
					}
				}
			}
		}
	}

	@Suite("xchachapoly tamper detection")
	struct XChaChaPolyTamperTests {

		private func zeroNonce() -> RAW_xchachapoly.Nonce {
			[UInt8](repeating: 0, count: 24).withUnsafeBytes { RAW_xchachapoly.Nonce(RAW_decode: $0)! }
		}

		private func zeroKey() -> RAW_chachapoly.Key32 {
			[UInt8](repeating: 0, count: 32).withUnsafeBytes { RAW_chachapoly.Key32(RAW_decode: $0)! }
		}

		private func encryptMessage() throws -> (ciphertext: [UInt8], tag: RAW_chachapoly.Tag) {
			var context = RAW_xchachapoly.Context(key: zeroKey())
			let message = Array("attack at dawn".utf8)
			let ad = [UInt8]([0x11, 0x22, 0x33])
			let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: message.count)
			defer {
				output.deallocate()
			}
			let tag = try message.withUnsafeBufferPointer { msg in
				try ad.withUnsafeBufferPointer { aad in
					try context.encrypt(nonce: zeroNonce(), associatedData: aad, inputData: msg, output: output.baseAddress!)
				}
			}
			return ([UInt8](output), tag)
		}

		@Test("decrypt rejects tampered ciphertext")
		func testCiphertextTamper() throws {
			let (ciphertext, tag) = try encryptMessage()
			var tampered = ciphertext
			tampered[0] ^= 0x01
			let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: tampered.count)
			defer {
				output.deallocate()
			}
			#expect(throws: RAW_chachapoly.InvalidMACError.self) {
				try tampered.withUnsafeBufferPointer { buf in
					let ad = [UInt8]([0x11, 0x22, 0x33])
					try ad.withUnsafeBufferPointer { aad in
						var context = RAW_xchachapoly.Context(key: zeroKey())
						try context.decrypt(tag: tag, nonce: zeroNonce(), associatedData: aad, inputData: buf, output: output.baseAddress!)
					}
				}
			}
		}

		@Test("decrypt rejects tampered tag")
		func testTagTamper() throws {
			let (ciphertext, tag) = try encryptMessage()
			var badTag = tag
			badTag.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { $0[0] ^= 0x01 }
			let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: ciphertext.count)
			defer {
				output.deallocate()
			}
			#expect(throws: RAW_chachapoly.InvalidMACError.self) {
				try ciphertext.withUnsafeBufferPointer { buf in
					let ad = [UInt8]([0x11, 0x22, 0x33])
					try ad.withUnsafeBufferPointer { aad in
						var context = RAW_xchachapoly.Context(key: zeroKey())
						try context.decrypt(tag: badTag, nonce: zeroNonce(), associatedData: aad, inputData: buf, output: output.baseAddress!)
					}
				}
			}
		}
	}
}
