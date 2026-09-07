// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import Testing
import RAW

@RAW_staticbuff(bytes:1)
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:true)
fileprivate struct _Int8:Sendable, RAW_native, Equatable {
}

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
fileprivate struct _Int16:Sendable, RAW_native, Equatable {
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
fileprivate struct _Int32:Sendable, RAW_native, Equatable {
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
fileprivate struct _Int64:Sendable, RAW_native, Equatable {
}

extension rawdog_tests {
	@Suite("IntTests")
	struct IntTests {
		@Test func testInt8() {
			let bytes:[UInt8] = [0xFF]
			let value = bytes.withUnsafeBytes { _Int8(RAW_decode:$0)! }
			#expect(value.RAW_native() == 0xFF)
		}

		@Test func testInt16() {
			let bytes:[UInt8] = [0xFF, 0xFF]
			let value = bytes.withUnsafeBytes { _Int16(RAW_decode:$0)! }
			#expect(value.RAW_native() == 0xFFFF)
		}

		@Test func testInt32() {
			let bytes:[UInt8] = [0xFF, 0xFF, 0xFF, 0xFF]
			let value = bytes.withUnsafeBytes { _Int32(RAW_decode:$0)! }
			#expect(value.RAW_native() == 0xFFFFFFFF)
		}

		@Test func testInt64() {
			let bytes:[UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
			let value = bytes.withUnsafeBytes { _Int64(RAW_decode:$0)! }
			#expect(value.RAW_native() == 0xFFFFFFFFFFFFFE00)
		}
	}
}
