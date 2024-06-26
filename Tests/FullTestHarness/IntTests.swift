// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
import RAW

@RAW_staticbuff(bytes:1)
@RAW_staticbuff_fixedwidthinteger_type<Int8>(bigEndian:true)
fileprivate struct _Int8:Sendable, ExpressibleByIntegerLiteral, Equatable {}

// test that the UInt8 type is correctly converting to and from a raw representation.
class RAWInt8Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value:_Int8 = -128
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0x80]
		XCTAssertEqual(bytes, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x80]
		let value = _Int8(RAW_decode:bytes)
		XCTAssertEqual(value, -128)
	}
}


@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<Int16>(bigEndian:true)
fileprivate struct _Int16:Sendable, ExpressibleByIntegerLiteral, Equatable {}

class RAWInt16Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value: _Int16 = -512
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0xFE, 0x00]
		XCTAssertEqual(bytes, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFE, 0x00]
		let value = _Int16(RAW_decode:bytes)
		XCTAssertEqual(value, -512)
	}
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<Int32>(bigEndian:true)
fileprivate struct _Int32:Sendable, ExpressibleByIntegerLiteral, Equatable {}

class RAWInt32Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value: _Int32 = -512
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes:[UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		XCTAssertEqual(bytes, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		let expected = _Int32(RAW_decode:bytes)
		XCTAssertEqual(expected, -512)
	}
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<Int64>(bigEndian:true)
fileprivate struct _Int64:Sendable, ExpressibleByIntegerLiteral, Equatable {}

class RAWInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value:_Int64 = -512
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		let value = _Int64(RAW_decode:bytes)
		XCTAssertEqual(value, -512)
	}
}