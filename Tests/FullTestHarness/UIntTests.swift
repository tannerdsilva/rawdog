// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import Testing
import RAW

@RAW_staticbuff(bytes:1)
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:true)
fileprivate struct _UInt8:Sendable, ExpressibleByIntegerLiteral, Equatable {}

extension rawdog_tests {
	// test that the UInt8 type is correctly converting to and from a raw representation.
	@Suite("RAWUInt8Tests")
	struct RAWUInt8Tests {
		@Test func testAsRAWVal() throws {
			var value: _UInt8 = 128
			var countout:size_t = 0
			let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let expectedBytes: [UInt8] = [0x80]
			#expect(rawVal == expectedBytes)
		}

		@Test func testInitWithRAWData() {
			let bytes: [UInt8] = [0x80]
			let value = _UInt8(RAW_decode:bytes)
			#expect(value == 128)
		}
	}
}

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
fileprivate struct _UInt16:Sendable, ExpressibleByIntegerLiteral, Equatable {}

extension rawdog_tests {
	@Suite("RAWUInt16Tests")
	struct RAWUInt16Tests {
		@Test func testAsRAWVal() throws {
			var value:_UInt16 = 512
			var countout:size_t = 0
			let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let expectedBytes: [UInt8] = [0x02, 0x00]
			#expect(rawVal == expectedBytes)
		}

		@Test func testInitWithRAWData() {
			var bytes: [UInt8] = [0x02, 0x00]
			let value = _UInt16(RAW_decode:&bytes)
			#expect(value == 512)
		}
	}
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
fileprivate struct _UInt32:Sendable, ExpressibleByIntegerLiteral, Equatable {}

extension rawdog_tests {
	@Suite("RAWUInt32Tests")
	struct RAWUInt32Tests {
		@Test func testAsRAWVal() throws {
			var value:_UInt32 = 512
			var countout:size_t = 0
			let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let expectedBytes:[UInt8] = [0x00, 0x00, 0x02, 0x00]
			#expect(rawVal == expectedBytes)
		}

		@Test func testInitWithRAWData() {
			let bytes:[UInt8] = [0x00, 0x00, 0x02, 0x00]
			let value = _UInt32(RAW_decode:bytes)
			#expect(value == 512)
		}
	}
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
fileprivate struct _UInt64:Sendable, ExpressibleByIntegerLiteral, Equatable {}

extension rawdog_tests {
	@Suite("RAWUInt64Tests")
	struct RAWUInt64Tests {
		@Test func testAsRAWVal() throws {
			var value:_UInt64 = 512
			var countout:size_t = 0
			let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let expectedBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
			#expect(rawVal == expectedBytes)
		}

		@Test func testInitWithRAWData() {
			let bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
			let value = _UInt64(RAW_decode:bytes)
			#expect(value == 512)
		}
	}
}