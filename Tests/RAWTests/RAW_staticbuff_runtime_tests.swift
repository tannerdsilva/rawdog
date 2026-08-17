// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import RAW

// MARK: - Test types at file scope (attached extension macros don't work on local types)

@RAW_staticbuff(bytes:2)
struct TwoBytes:RAW_staticbuff, RAW_decodable, Equatable, Comparable {}

@RAW_staticbuff(bytes:4)
struct FourBytes:RAW_staticbuff, RAW_decodable, Equatable, Comparable {}

@RAW_staticbuff(bytes:4)
struct FourBytesHashable:RAW_staticbuff, RAW_decodable, Hashable {}

@RAW_staticbuff(bytes:8)
struct EightBytes:RAW_staticbuff, RAW_decodable, Equatable, Comparable {}

@RAW_staticbuff(bytes:1)
struct TestU8:RAW_staticbuff, RAW_decodable, RAW_native, Equatable {
	#RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:false)
}

@RAW_staticbuff(bytes:4)
struct TestU32BE:RAW_staticbuff, RAW_decodable, RAW_native, Equatable {
	#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
}

// MARK: - Protocol Conformance Tests

@Suite("Runtime: RAW_staticbuff protocol conformance", .serialized)
struct RAW_staticbuff_protocol_tests {
	@Test("RAW_decodable - init from buffer succeeds with correct size")
	func testDecodableCorrectSize() throws {
		let bytes:[UInt8] = [0x01, 0x02]
		let result = bytes.withUnsafeBytes { buf in
			TwoBytes(RAW_decode: buf)
		}
		#expect(result != nil)
	}

	@Test("RAW_decodable - init from buffer fails with incorrect size")
	func testDecodableWrongSize() throws {
		let bytes:[UInt8] = [0x01] // 1 byte, but TwoBytes needs 2
		let result = bytes.withUnsafeBytes { buf in
			TwoBytes(RAW_decode: buf)
		}
		#expect(result == nil)
	}

	@Test("RAW_decodable - init from buffer preserves data")
	func testDecodableDataPreservation() throws {
		let bytes:[UInt8] = [0xAB, 0xCD]
		let decoded = bytes.withUnsafeBytes { buf -> TwoBytes? in
			TwoBytes(RAW_decode: buf)
		}
		let reEncoded = decoded!.RAW_access_immutable(UnsafeRawBufferPointer.self) { buf in
			[UInt8](buf)
		}
		#expect(reEncoded == bytes)
	}

	@Test("RAW_encodable - encode count matches type size")
	func testEncodableCount() throws {
		let val = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		var count:Int = 0
		val.RAW_encode(count: &count)
		#expect(count == 2)
	}

	@Test("RAW_encodable - encode to destination returns advanced pointer")
	func testEncodableDestination() throws {
		let val = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		var storage = [UInt8](repeating: 0, count: 4)
		let next = storage.withUnsafeMutableBytes { buf in
			val.RAW_encode(UnsafeMutableRawPointer.self, destination: buf.baseAddress!)
		}
		#expect(next == storage.withUnsafeMutableBytes { $0.baseAddress!.advanced(by: 2) })
	}

	@Test("RAW_comparable - equal data returns 0")
	func testComparableEqual() throws {
		let a = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		let b = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		let result = a.RAW_access_immutable(UnsafeRawBufferPointer.self) { aBuf in
			b.RAW_access_immutable(UnsafeRawBufferPointer.self) { bBuf in
				TwoBytes.RAW_compare(lhs_data: aBuf.baseAddress!, lhs_count: aBuf.count, rhs_data: bBuf.baseAddress!, rhs_count: bBuf.count)
			}
		}
		#expect(result == 0)
	}

	@Test("RAW_comparable - different data returns non-zero")
	func testComparableNotEqual() throws {
		var aBytes = TwoBytes.RAW_staticbuff_zeroed()
		withUnsafeMutablePointer(to: &aBytes) { ptr in
			ptr.withMemoryRebound(to: UInt8.self, capacity: 2) { bytePtr in
				bytePtr[0] = 0x01
			}
		}
		let a = TwoBytes(RAW_staticbuff:aBytes)
		let b = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		let result = a.RAW_access_immutable(UnsafeRawBufferPointer.self) { aBuf in
			b.RAW_access_immutable(UnsafeRawBufferPointer.self) { bBuf in
				TwoBytes.RAW_compare(lhs_data: aBuf.baseAddress!, lhs_count: aBuf.count, rhs_data: bBuf.baseAddress!, rhs_count: bBuf.count)
			}
		}
		#expect(result != 0)
	}

	@Test("RAW_accessible_immutable - access returns correct buffer")
	func testAccessImmutable() throws {
		let val = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		let count = val.RAW_access_immutable(UnsafeRawBufferPointer.self) { buf in
			buf.count
		}
		#expect(count == 2)
	}

	@Test("RAW_accessible_mutable - mutation persists")
	func testAccessMutable() throws {
		var val = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		val.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buf in
			buf.storeBytes(of: 0xAB, as: UInt8.self)
		}
		let firstByte = val.RAW_access_immutable(UnsafeRawBufferPointer.self) { buf in
			buf.load(as: UInt8.self)
		}
		#expect(firstByte == 0xAB)
	}
}

// MARK: - Seeking Init Tests

@Suite("Runtime: RAW_staticbuff seeking init", .serialized)
struct RAW_staticbuff_seeking_tests {
	@Test("Seeking init - advances pointer by type size")
	func testSeekingInitAdvances() throws {
		var bytes:[UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
		let result = bytes.withUnsafeBytes { rawPtr in
			var seeker = rawPtr.baseAddress!
			let first = FourBytes(RAW_staticbuff_seeking: &seeker)
			let second = FourBytes(RAW_staticbuff_seeking: &seeker)
			return (first, second, seeker)
		}
		#expect(result.2 == bytes.withUnsafeBytes { $0.baseAddress!.advanced(by: 8) })
	}

	@Test("Seeking init - reads correct data")
	func testSeekingInitReadsCorrectly() throws {
		var bytes:[UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
		let result = bytes.withUnsafeBytes { rawPtr in
			var seeker = rawPtr.baseAddress!
			let first = FourBytes(RAW_staticbuff_seeking: &seeker)
			return first
		}
		let firstByte = result.RAW_access_immutable(UnsafeRawBufferPointer.self) { buf in
			buf.load(as: UInt8.self)
		}
		#expect(firstByte == 0x01)
	}
}

// MARK: - Bitwise NOT Operator Tests

@Suite("Runtime: RAW_staticbuff bitwise NOT", .serialized)
struct RAW_staticbuff_not_tests {
	@Test("Bitwise NOT - inverts all bytes")
	func testBitwiseNOTInverts() throws {
		var valBytes = FourBytes.RAW_staticbuff_zeroed()
		withUnsafeMutablePointer(to: &valBytes) { ptr in
			ptr.withMemoryRebound(to: UInt8.self, capacity: 4) { bytePtr in
				bytePtr[0] = 0xFF; bytePtr[1] = 0xFF; bytePtr[2] = 0xFF; bytePtr[3] = 0xFF
			}
		}
		let val = FourBytes(RAW_staticbuff:valBytes)
		let inverted = ~val
		let zeroed = FourBytes(RAW_staticbuff:FourBytes.RAW_staticbuff_zeroed())
		#expect(inverted == zeroed)
	}

	@Test("Bitwise NOT - double inversion returns original")
	func testBitwiseNOTDouble() throws {
		var valBytes = FourBytes.RAW_staticbuff_zeroed()
		withUnsafeMutablePointer(to: &valBytes) { ptr in
			ptr.withMemoryRebound(to: UInt8.self, capacity: 4) { bytePtr in
				bytePtr[0] = 0xAB; bytePtr[1] = 0xCD; bytePtr[2] = 0xEF; bytePtr[3] = 0x12
			}
		}
		let val = FourBytes(RAW_staticbuff:valBytes)
		#expect(~(~val) == val)
	}
}

// MARK: - Native Type Integration Tests

@Suite("Runtime: RAW_native integration", .serialized)
struct RAW_native_runtime_tests {
	@Test("RAW_native - round-trip UInt8 preserves value")
	func testNativeUInt8RoundTrip() throws {
		let original = TestU8(RAW_native: UInt8(0xAB))
		let back = original.RAW_native()
		#expect(back == 0xAB)
	}

	@Test("RAW_native - round-trip UInt32 big-endian preserves value")
	func testNativeUInt32BERoundTrip() throws {
		let original = TestU32BE(RAW_native: UInt32(0x01020304))
		let back = original.RAW_native()
		#expect(back == 0x01020304)
	}

	@Test("RAW_native - big-endian encoding stores bytes in correct order")
	func testNativeU32BEBytes() throws {
		let val = TestU32BE(RAW_native: UInt32(0x01020304))
		let bytes = val.RAW_access_immutable(UnsafeRawBufferPointer.self) { buf in
			[UInt8](buf)
		}
		#expect(bytes == [0x01, 0x02, 0x03, 0x04])
	}
}
