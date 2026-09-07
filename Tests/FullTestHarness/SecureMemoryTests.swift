// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import RAW
import RAW_dh25519

extension rawdog_tests {
	@Suite("secure memory utilities")
	struct SecureMemoryTests {

		@Test("secureZeroBytes clears an UnsafeMutableRawPointer")
		func testZeroRawPointer() throws {
			let buffer = UnsafeMutableRawPointer.allocate(byteCount: 64, alignment: 1)
			defer {
				buffer.deallocate()
			}
			buffer.initializeMemory(as: UInt8.self, repeating: 0xAA, count: 64)
			try secureZeroBytes(buffer, count: 64)
			let bytes = [UInt8](UnsafeRawBufferPointer(start: buffer, count: 64))
			#expect(bytes.allSatisfy { $0 == 0 })
		}

		@Test("secureZeroBytes clears an UnsafeMutableRawBufferPointer")
		func testZeroRawBuffer() throws {
			let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 64, alignment: 1)
			defer {
				buffer.deallocate()
			}
			buffer.initializeMemory(as: UInt8.self, repeating: 0xAA)
			try secureZeroBytes(buffer)
			#expect(buffer.allSatisfy { $0 == 0 })
		}

		@Test("secureZeroBytes clears an UnsafeMutableBufferPointer<UInt8>")
		func testZeroByteBuffer() throws {
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 64)
			defer {
				buffer.deallocate()
			}
			buffer.initialize(repeating: 0xAA)
			let typed = UnsafeMutableBufferPointer<UInt8>(start: buffer.baseAddress, count: buffer.count)
			try secureZeroBytes(typed)
			#expect(buffer.allSatisfy { $0 == 0 })
		}

		@Test("generateSecureRandomBytes returns exactly the requested count")
		func testRandomCount() throws {
			for count in [0, 1, 32, 256] {
				let bytes = try generateSecureRandomBytes(count: count)
				#expect(bytes.count == count)
			}
		}

		@Test("generateSecureRandomBytes returns distinct values")
		func testRandomDistinct() throws {
			let first = try generateSecureRandomBytes(count: 32)
			let second = try generateSecureRandomBytes(count: 32)
			#expect(first != second)
		}

		@Test("generateSecureRandomBytes rejects counts above the 256-byte cap")
		func testRandomTooLarge() {
			#expect(throws: InvalidSecureRandomBytesLengthError.self) {
				_ = try generateSecureRandomBytes(count: 257)
			}
		}
	}

	@Suite("MemoryGuarded")
	struct MemoryGuardedTests {

		@Test("blank() yields zeroed storage")
		func testBlank() throws {
			let guarded = try MemoryGuarded<RAW_dh25519.PrivateKey>.blank()
			guarded.RAW_access_immutable(UnsafeRawBufferPointer.self) { buffer in
				#expect(buffer.count == MemoryLayout<RAW_dh25519.PrivateKey>.size)
				#expect(buffer.allSatisfy { $0 == 0 })
			}
		}

		@Test("decode accepts only the exact fixed size")
		func testDecodeGuard() throws {
			let exact = [UInt8](repeating: 0x42, count: 32)
			let ok = exact.withUnsafeBytes { MemoryGuarded<RAW_dh25519.PrivateKey>(RAW_decode: $0) }
			#expect(ok != nil)

			let short = Array(exact.dropLast(4))
			let tooSmall = short.withUnsafeBytes { MemoryGuarded<RAW_dh25519.PrivateKey>(RAW_decode: $0) }
			#expect(tooSmall == nil)

			let long = exact + exact
			let tooLarge = long.withUnsafeBytes { MemoryGuarded<RAW_dh25519.PrivateKey>(RAW_decode: $0) }
			#expect(tooLarge == nil)
		}

		@Test("mutable writes are visible through immutable access")
		func testAccessPassthrough() throws {
			let guarded = try MemoryGuarded<RAW_dh25519.PrivateKey>.blank()
			guarded.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buffer in
				buffer[0] = 0xAB
				buffer[31] = 0xCD
			}
			guarded.RAW_access_immutable(UnsafeRawBufferPointer.self) { buffer in
				#expect(buffer[0] == 0xAB)
				#expect(buffer[31] == 0xCD)
			}
		}
	}
}
