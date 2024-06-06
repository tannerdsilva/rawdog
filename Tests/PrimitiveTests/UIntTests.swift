// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import XCTest
import RAW

@RAW_staticbuff(bytes:1)
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:true)
fileprivate struct _UInt8:Sendable, ExpressibleByIntegerLiteral, Equatable {}

// test that the UInt8 type is correctly converting to and from a raw representation.
class RAWUInt8Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value: _UInt8 = 128
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0x80]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x80]
		let value = _UInt8(RAW_decode:bytes)
		XCTAssertEqual(value, 128)
	}
}

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
fileprivate struct _UInt16:Sendable, ExpressibleByIntegerLiteral, Equatable {}

class RAWUInt16Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value:_UInt16 = 512
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		var bytes: [UInt8] = [0x02, 0x00]
		let value = _UInt16(RAW_decode:&bytes)
		XCTAssertEqual(value, 512)
	}
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
fileprivate struct _UInt32:Sendable, ExpressibleByIntegerLiteral, Equatable {}

class RAWUInt32Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value:_UInt32 = 512
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes:[UInt8] = [0x00, 0x00, 0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes:[UInt8] = [0x00, 0x00, 0x02, 0x00]
		let value = _UInt32(RAW_decode:bytes)
		XCTAssertEqual(value, 512)
	}
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
fileprivate struct _UInt64:Sendable, ExpressibleByIntegerLiteral, Equatable {}

class RAWUInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		var value:_UInt64 = 512
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		let value = _UInt64(RAW_decode:bytes)
		XCTAssertEqual(value, 512)
	}
}
