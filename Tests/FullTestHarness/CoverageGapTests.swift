// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import RAW
@testable import RAW_dh25519
@testable import RAW_hex

extension rawdog_tests {
	
	// MARK: - RAW_dh25519
	
	@Suite("Curve25519 key exchange")
	struct Curve25519Tests {
		@Test("key generation and shared secret computation")
		func testKeyExchange() throws {
			let alicePrivate = try MemoryGuarded<PrivateKey>.new()
			let alicePublic = PublicKey(privateKey: alicePrivate)
			
			let bobPrivate = try MemoryGuarded<PrivateKey>.new()
			let bobPublic = PublicKey(privateKey: bobPrivate)
			
			let aliceShared = try MemoryGuarded<SharedKey>.compute(privateKey: alicePrivate, publicKey: bobPublic)
			let bobShared = try MemoryGuarded<SharedKey>.compute(privateKey: bobPrivate, publicKey: alicePublic)
			
			// Both sides should derive the same shared key
			let aliceBytes = aliceShared.RAW_access_immutable(UnsafeRawBufferPointer.self) { $0 }
			let bobBytes = bobShared.RAW_access_immutable(UnsafeRawBufferPointer.self) { $0 }
			#expect(aliceBytes.count == bobBytes.count)
			#expect(aliceBytes.elementsEqual(bobBytes))
		}
		
		@Test("public key derivation is deterministic")
		func testDeterministicPublicKey() throws {
			let privateKey = try MemoryGuarded<PrivateKey>.new()
			let publicKey1 = PublicKey(privateKey: privateKey)
			let publicKey2 = PublicKey(privateKey: privateKey)
			
			#expect(publicKey1 == publicKey2)
		}
		
		@Test("key types have correct size")
		func testKeySizes() {
			#expect(MemoryLayout<PrivateKey>.size == 32)
			#expect(MemoryLayout<PublicKey>.size == 32)
			#expect(MemoryLayout<SharedKey>.size == 32)
		}
	}
	
	// MARK: - RAW_hasher protocol
	
	/// A minimal RAW_hasher conformer for protocol testing
	@RAW_staticbuff(bytes: 4)
	@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
	struct TestHashOutput: RAW_staticbuff, RAW_accessible_mutable, RAW_native, Sendable, Equatable {
	}
	
	struct TestHasher: RAW_hasher {
		static var RAW_hasher_blocksize: Int { 64 }
		typealias RAW_hasher_outputtype = TestHashOutput
		
		private var state: UInt32 = 0
		
		init() throws {}
		
		mutating func update(_ data: UnsafeRawBufferPointer) throws {
			for byte in data {
				state = state &+ UInt32(byte)
			}
		}
		
		mutating func finish(into output: UnsafeMutableRawPointer) throws {
			var result = TestHashOutput(RAW_native: state)
			result.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buf in
				output.copyMemory(from: UnsafeRawPointer(buf.baseAddress!), byteCount: buf.count)
			}
		}
	}
	
	@Suite("RAW_hasher protocol conformance")
	struct HasherProtocolTests {
		@Test("all protocol requirements compile and run")
		func testHasherProtocol() throws {
			var hasher = try TestHasher()
			
			let data: [UInt8] = [1, 2, 3, 4, 5]
			try data.withUnsafeBytes { buf in
				try hasher.update(buf)
			}
			
			try data.withUnsafeBufferPointer { buf in
				try hasher.update(buf)
			}
			
			try data.withUnsafeBytes { buf in
				try hasher.update(buf.baseAddress!, count: buf.count)
			}
			
			var output = [UInt8](repeating: 0, count: 4).withUnsafeBytes { TestHashOutput(RAW_decode: $0)! }
			try output.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buf in
				try hasher.finish(into: buf.baseAddress!)
			}
		}
		
		@Test("update via UnsafeBufferPointer<UInt8>")
		func testUpdateTypedBuffer() throws {
			var hasher = try TestHasher()
			let data: [UInt8] = [10, 20, 30]
			try data.withUnsafeBufferPointer { buf in
				try hasher.update(buf)
			}
		}
		
		@Test("update via UnsafeRawPointer + count")
		func testUpdateRawPointer() throws {
			var hasher = try TestHasher()
			let data: [UInt8] = [10, 20, 30]
			try data.withUnsafeBytes { buf in
				try hasher.update(buf.baseAddress!, count: buf.count)
			}
		}
	}
	
	// MARK: - RAW_encoded_unicode
	
	@RAW_staticbuff(bytes: 2)
	@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian: true)
	struct _UTF16Char: RAW_encoded_fixedwidthinteger, Sendable {
	}
	
	@RAW_convertible_string_type<UTF16>(backing: _UTF16Char.self)
	struct TestUTF16String: Sendable {}
	
	@Suite("RAW_encoded_unicode via @RAW_convertible_string_type")
	struct ConvertibleStringTypeTests {
		@Test("init from String")
		func testStringInit() {
			let s = TestUTF16String("Hello")
			// Verify it's accessible as raw bytes
			let count = s.RAW_access_immutable(UnsafeRawBufferPointer.self) { $0.count }
			#expect(count > 0)
		}
		
		@Test("init from UnicodeScalarView")
		func testUnicodeScalarInit() {
			let scalars = "World".unicodeScalars
			let s = TestUTF16String(scalars)
			let count = s.RAW_access_immutable(UnsafeRawBufferPointer.self) { $0.count }
			#expect(count > 0)
		}
		
		@Test("iterator produces characters")
		func testIterator() {
			let s = TestUTF16String("Hi")
			var iter = s.makeIterator()
			#expect(iter.next() == "H")
			#expect(iter.next() == "i")
			#expect(iter.next() == nil)
		}
	}
	
	// MARK: - RAW_hex Sequence conformances
	
	@Suite("RAW_hex sequence conformances")
	struct HexSequenceTests {
		@Test("Encoded startIndex and endIndex")
		func testIndices() {
			let encoded = RAW_hex.encode([0xDE, 0xAD, 0xBE, 0xEF])
			#expect(encoded.startIndex == 0)
			#expect(encoded.endIndex == 8) // 4 bytes = 8 hex chars
		}
		
		@Test("Encoded subscript access")
		func testSubscript() {
			let encoded = RAW_hex.encode([0xFF, 0x00] as [UInt8])
			#expect(encoded[0] == "f")
			#expect(encoded[1] == "f")
			#expect(encoded[2] == "0")
			#expect(encoded[3] == "0")
		}
		
		@Test("Encoded iteration produces correct characters")
		func testIteration() {
			let encoded = RAW_hex.encode([0xAB, 0xCD] as [UInt8])
			let chars = Array(encoded).map { $0.characterValue() }
			#expect(chars.count == 4)
			#expect(String(chars) == "abcd")
		}
		
		@Test("Encoded count property")
		func testCount() {
			let encoded = RAW_hex.encode([0x01, 0x02, 0x03])
			#expect(encoded.count == 6) // 3 bytes = 6 hex chars
		}
		
		@Test("empty hex encoding indices")
		func testEmptyIndices() {
			let encoded: RAW_hex.Encoded = RAW_hex.encode([UInt8]())
			#expect(encoded.startIndex == 0)
			#expect(encoded.endIndex == 0)
			#expect(encoded.count == 0)
		}
	}
}
