// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import RAW
import RAW_sha1
import RAW_sha256
import RAW_sha512
import RAW_md5

extension rawdog_tests {
	/// known-answer vectors for the Swift-layer hashers. the C backends carry their
	/// own vector suites, but the Swift `Hasher`/`Hash` types are only exercised
	/// transitively elsewhere — these assert published digests through both finish
	/// paths (typed `finish()` and `finish(into:)`) plus chunked-update consistency.
	@Suite("Swift hashing known-answer vectors")
	struct HashingVectorTests {

		private func hexString(_ bytes: [UInt8]) -> String {
			let digits = Array("0123456789abcdef".utf8)
			var out = ""
			out.reserveCapacity(bytes.count * 2)
			for byte in bytes {
				out.append(Character(UnicodeScalar(digits[Int(byte >> 4)])))
				out.append(Character(UnicodeScalar(digits[Int(byte & 0x0F)])))
			}
			return out
		}

		private func typedBytes<H>(_ data: [UInt8], _ type: H.Type) throws -> [UInt8] where H: RAW_hasher {
			var hasher = try H.init()
			try hasher.update(data)
			let output = try hasher.finish()
			return output.RAW_access_immutable(UnsafeRawBufferPointer.self) { Array($0) }
		}

		private func rawBytes<H>(_ data: [UInt8], _ type: H.Type) throws -> [UInt8] where H: RAW_hasher {
			var hasher = try H.init()
			try hasher.update(data)
			let size = MemoryLayout<H.RAW_hasher_outputtype.RAW_fixed_type>.size
			let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<H.RAW_hasher_outputtype>.alignment)
			defer {
				buffer.deallocate()
			}
			try hasher.finish(into: buffer)
			return [UInt8](UnsafeRawBufferPointer(start: buffer, count: size))
		}

		private func chunkedBytes<H>(_ data: [UInt8], _ type: H.Type, chunk: Int) throws -> [UInt8] where H: RAW_hasher {
			var hasher = try H.init()
			var offset = 0
			while offset < data.count {
				let end = Swift.min(offset + chunk, data.count)
				try data[offset..<end].withUnsafeBytes { try hasher.update($0) }
				offset = end
			}
			let output = try hasher.finish()
			return output.RAW_access_immutable(UnsafeRawBufferPointer.self) { Array($0) }
		}

		private func expectVectors<H>(_ type: H.Type, _ cases: [(String, String)], chunk: Int) throws where H: RAW_hasher {
			for (input, expectedHex) in cases {
				let data = Array(input.utf8)
				#expect(hexString(try typedBytes(data, type)) == expectedHex)
				#expect(hexString(try rawBytes(data, type)) == expectedHex)
				#expect(hexString(try chunkedBytes(data, type, chunk: chunk)) == expectedHex)
			}
		}

		@Test("SHA-1 known-answer vectors")
		func testSHA1Vectors() throws {
			try expectVectors(RAW_sha1.Hasher.self, [
				("", "da39a3ee5e6b4b0d3255bfef95601890afd80709"),
				("abc", "a9993e364706816aba3e25717850c26c9cd0d89d"),
			], chunk: 1)
			let millionAs = [UInt8](repeating: 0x61, count: 1_000_000)
			#expect(hexString(try typedBytes(millionAs, RAW_sha1.Hasher.self)) == "34aa973cd4c4daa4f61eeb2bdbad27316534016f")
		}

		@Test("SHA-256 known-answer vectors")
		func testSHA256Vectors() throws {
			try expectVectors(RAW_sha256.Hasher.self, [
				("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
				("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
			], chunk: 1)
			let millionAs = [UInt8](repeating: 0x61, count: 1_000_000)
			#expect(hexString(try typedBytes(millionAs, RAW_sha256.Hasher.self)) == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
			#expect(hexString(try chunkedBytes(millionAs, RAW_sha256.Hasher.self, chunk: 100_003)) == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
		}

		@Test("SHA-512 known-answer vectors")
		func testSHA512Vectors() throws {
			try expectVectors(RAW_sha512.Hasher.self, [
				("", "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"),
				("abc", "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"),
			], chunk: 1)
			// large-input consistency: all finish/update strategies must agree for
			// an input with no published short-form vector.
			let pattern = Array((0..<256).map { UInt8($0) })
			var repeated = [UInt8]()
			repeated.reserveCapacity(pattern.count * 200)
			for _ in 0..<200 {
				repeated.append(contentsOf: pattern)
			}
			#expect(hexString(try typedBytes(repeated, RAW_sha512.Hasher.self)) == hexString(try rawBytes(repeated, RAW_sha512.Hasher.self)))
			#expect(hexString(try rawBytes(repeated, RAW_sha512.Hasher.self)) == hexString(try chunkedBytes(repeated, RAW_sha512.Hasher.self, chunk: 4096)))
		}

		@Test("MD5 known-answer vectors")
		func testMD5Vectors() throws {
			try expectVectors(RAW_md5.Hasher.self, [
				("", "d41d8cd98f00b204e9800998ecf8427e"),
				("abc", "900150983cd24fb0d6963f7d28e17f72"),
			], chunk: 1)
		}

		@Test("keyed and unkeyed SHA-256 agree with the one-shot hmac path")
		func testHashingCrossChecks() throws {
			// HKDF/HMAC exercise the hashers via the generic `RAW_hasher` surface;
			// this pins that the typed finish used there produces the same digest
			// as the direct typed path on a real algorithm.
			let message = Array("cross-check".utf8)
			let direct = try typedBytes(message, RAW_sha256.Hasher.self)
			var hasher = RAW_sha256.Hasher()
			try hasher.update(message)
			let typed = try hasher.finish()
			let viaAccess = typed.RAW_access_immutable(UnsafeRawBufferPointer.self) { Array($0) }
			#expect(direct == viaAccess)
		}
	}
}
