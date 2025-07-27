// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import RAW

@RAW_staticbuff(bytes:1)
@RAW_staticbuff_fixedwidthinteger_type<Int8>(bigEndian:true)
fileprivate struct _Int8:Sendable, ExpressibleByIntegerLiteral, Equatable {}

extension rawdog_tests {

}

// test that the UInt8 type is correctly converting to and from a raw representation.
@Suite("RAWInt8Tests")
struct RAWInt8Tests {
	func testAsRAWVal() throws {
		var value:_Int8 = -128
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0x80]
		#expect(bytes == expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x80]
		let value = _Int8(RAW_decode:bytes)
		#expect(value == -128)
	}
}


@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<Int16>(bigEndian:true)
fileprivate struct _Int16:Sendable, ExpressibleByIntegerLiteral, Equatable {}

@Suite("RAWInt16Tests")
struct RAWInt16Tests {
	@Test func testAsRAWVal() throws {
		var value: _Int16 = -512
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0xFE, 0x00]
		#expect(bytes == expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFE, 0x00]
		let value = _Int16(RAW_decode:bytes)
		#expect(value == -512)
	}
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<Int32>(bigEndian:true)
fileprivate struct _Int32:Sendable, ExpressibleByIntegerLiteral, Equatable {}
@Suite("RAWInt32Tests")
struct RAWInt32Tests {
	@Test func testAsRAWVal() throws {
		var value: _Int32 = -512
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes:[UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		#expect(bytes == expectedBytes)
	}
	
	@Test func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		let expected = _Int32(RAW_decode:bytes)
		#expect(expected == -512)
	}
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<Int64>(bigEndian:true)
fileprivate struct _Int64:Sendable, ExpressibleByIntegerLiteral, Equatable {}

@Suite("RAWInt64Tests")
struct RAWInt64Tests {
	@Test func testAsRAWVal() throws {
		var value:_Int64 = -512
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		#expect(rawVal == expectedBytes)
	}
	
	@Test func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		let value = _Int64(RAW_decode:bytes)
		#expect(value == -512)
	}
}