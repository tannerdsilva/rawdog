// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import RAW

// Test types at file scope (attached extension macros don't work on local types)
@RAW_staticbuff(bytes:2)
struct TwoBytes:RAW_staticbuff, RAW_decodable, Equatable, Comparable {}

@RAW_staticbuff(bytes:4)
struct FourBytes:RAW_staticbuff, RAW_decodable, Equatable, Comparable {}

@RAW_staticbuff(bytes:4)
struct FourBytesHashable:RAW_staticbuff, RAW_decodable, Hashable {}

@Suite("Runtime: RAW_staticbuff features", .serialized)
struct RAW_staticbuff_runtime_tests {
	@Test("Equatable sugar - equal values return true")
	func testEquatableEqual() throws {
		let a = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		let b = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		#expect(a == b)
		#expect(!(a != b))
	}

	@Test("Equatable sugar - different values return false")
	func testEquatableNotEqual() throws {
		var aBytes = TwoBytes.RAW_staticbuff_zeroed()
		withUnsafeMutablePointer(to: &aBytes) { ptr in
			ptr.withMemoryRebound(to: UInt8.self, capacity: 2) { bytePtr in
				bytePtr[0] = 0x01
			}
		}
		let a = TwoBytes(RAW_staticbuff:aBytes)
		let b = TwoBytes(RAW_staticbuff:TwoBytes.RAW_staticbuff_zeroed())
		#expect(a != b)
		#expect(!(a == b))
	}

	@Test("Comparable sugar - ordering works")
	func testComparableOrdering() throws {
		var smallBytes = TwoBytes.RAW_staticbuff_zeroed()
		var bigBytes = TwoBytes.RAW_staticbuff_zeroed()
		withUnsafeMutablePointer(to: &bigBytes) { ptr in
			ptr.withMemoryRebound(to: UInt8.self, capacity: 2) { bytePtr in
				bytePtr[0] = 0xFF
			}
		}
		let small = TwoBytes(RAW_staticbuff:smallBytes)
		let big = TwoBytes(RAW_staticbuff:bigBytes)
		#expect(small < big)
		#expect(big > small)
		#expect(!(small > big))
		#expect(!(big < small))
	}

	@Test("Seeking init - advances pointer correctly")
	func testSeekingInit() throws {
		var bytes:[UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
		let result = bytes.withUnsafeBytes { rawPtr in
			var seeker = rawPtr.baseAddress!
			let first = FourBytes(RAW_staticbuff_seeking: &seeker)
			let second = FourBytes(RAW_staticbuff_seeking: &seeker)
			return (first, second, seeker)
		}
		// Verify pointer advanced by 8 bytes (4 + 4)
		#expect(result.2 == bytes.withUnsafeBytes { $0.baseAddress!.advanced(by: 8) })
	}

	@Test("Bitwise NOT operator - inverts all bytes")
	func testBitwiseNOT() throws {
		var valBytes = FourBytes.RAW_staticbuff_zeroed()
		// Set all bytes to 0xFF
		withUnsafeMutablePointer(to: &valBytes) { ptr in
			ptr.withMemoryRebound(to: UInt8.self, capacity: 4) { bytePtr in
				bytePtr[0] = 0xFF; bytePtr[1] = 0xFF; bytePtr[2] = 0xFF; bytePtr[3] = 0xFF
			}
		}
		let val = FourBytes(RAW_staticbuff:valBytes)
		let inverted = ~val
		// All bytes should now be 0x00 (inverse of 0xFF)
		let zeroed = FourBytes(RAW_staticbuff:FourBytes.RAW_staticbuff_zeroed())
		#expect(inverted == zeroed)
		// Double inversion should return original
		#expect(~(~val) == val)
	}

	@Test("Hashable conformance - equal values have equal hashes")
	func testHashable() throws {
		let a = FourBytesHashable(RAW_staticbuff:FourBytesHashable.RAW_staticbuff_zeroed())
		let b = FourBytesHashable(RAW_staticbuff:FourBytesHashable.RAW_staticbuff_zeroed())
		var hasherA = Hasher()
		var hasherB = Hasher()
		a.hash(into: &hasherA)
		b.hash(into: &hasherB)
		#expect(hasherA.finalize() == hasherB.finalize())
	}
}
