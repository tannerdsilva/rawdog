// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import Foundation
import RAW

extension rawdog_tests {
	@Suite("RAW_byte")
	struct RAWByteTests {

		@Test("native value round trip")
		func testNativeRoundTrip() {
			let byte = RAW_byte(RAW_native: 0x7F)
			#expect(byte.RAW_native() == 0x7F)
		}

		@Test("encode reports one byte and writes it")
		func testEncode() {
			let byte = RAW_byte(RAW_native: 0x42)
			var count = 0
			byte.RAW_encode(count: &count)
			#expect(count == 1)
			var out = [UInt8](repeating: 0, count: 1)
			out.withUnsafeMutableBufferPointer { raw in
				_ = byte.RAW_encode(UnsafeMutableRawPointer.self, destination: UnsafeMutableRawPointer(raw.baseAddress!))
			}
			#expect(out == [0x42])
		}

		@Test("decode round trip")
		func testDecode() {
			let data = [UInt8]([0x99])
			let byte = data.withUnsafeBytes { RAW_byte(RAW_decode: $0) }
			#expect(byte?.RAW_native() == 0x99)
		}

		@Test("encode byte then decode reproduces the value")
		func testEncodeDecodeRoundTrip() throws {
			let byte = RAW_byte(RAW_native: 0x5A)
			var count = 0
			byte.RAW_encode(count: &count)
			var bytes = [UInt8](repeating: 0, count: count)
			bytes.withUnsafeMutableBufferPointer { raw in
				_ = byte.RAW_encode(UnsafeMutableRawPointer.self, destination: UnsafeMutableRawPointer(raw.baseAddress!))
			}
			let decoded = bytes.withUnsafeBytes { RAW_byte(RAW_decode: $0) }
			#expect(decoded == byte)
		}

		@Test("equality, hashability, and ordering")
		func testConsistentChips() {
			let a = RAW_byte(RAW_native: 0x01)
			let c = RAW_byte(RAW_native: 0x02)
			#expect(a == RAW_byte(RAW_native: 0x01))
			#expect(a != c)
			#expect(a < c)

			var h1 = Hasher()
			a.hash(into: &h1)
			var h2 = Hasher()
			RAW_byte(RAW_native: 0x01).hash(into: &h2)
			#expect(h1.finalize() == h2.finalize())
		}

		@Test("codable round trip")
		func testCodable() throws {
			let byte = RAW_byte(RAW_native: 0x55)
			let encoded = try JSONEncoder().encode(byte)
			let decoded = try JSONDecoder().decode(RAW_byte.self, from: encoded)
			#expect(decoded == byte)
		}

		@Test("debug description shows the wrapped value")
		func testDebugDescription() {
			#expect(RAW_byte(RAW_native: 0x2A).debugDescription == "42")
		}
	}
}
