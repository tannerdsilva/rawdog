// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import Testing
import RAW

@RAW_staticbuff(bytes:1)
fileprivate struct _UInt8:Sendable, RAW_native, Equatable {
	#RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:true)
}

@RAW_staticbuff(bytes:2)
fileprivate struct _UInt16:Sendable, RAW_native, Equatable {
	#RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
}

@RAW_staticbuff(bytes:4)
fileprivate struct _UInt32:Sendable, RAW_native, Equatable {
	#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
}

@RAW_staticbuff(bytes:8)
fileprivate struct _UInt64:Sendable, RAW_native, Equatable {
	#RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
}

extension rawdog_tests {
	@Suite("UIntTests")
	struct UIntTests {
		@Test func testUInt8() {
			let bytes:[UInt8] = [0xAB]
			let value = bytes.withUnsafeBytes { _UInt8(RAW_decode:$0)! }
			#expect(value.RAW_native() == 0xAB)
		}

		@Test func testUInt16() {
			var bytes:[UInt8] = [0xAB, 0xCD]
			let value = bytes.withUnsafeBytes { buf in var p = buf.baseAddress!; return _UInt16(RAW_staticbuff_seeking:&p) }
			#expect(value.RAW_native() == 0xABCD)
		}

		@Test func testUInt32() {
			let bytes:[UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
			let value = bytes.withUnsafeBytes { _UInt32(RAW_decode:$0)! }
			#expect(value.RAW_native() == 0xDEADBEEF)
		}

		@Test func testUInt64() {
			let bytes:[UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
			let value = bytes.withUnsafeBytes { _UInt64(RAW_decode:$0)! }
			#expect(value.RAW_native() == 0x0102030405060708)
		}
	}
}
