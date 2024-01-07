import XCTest
@testable import RAW

// test that the UInt type is correctly converting to and from a raw representation.
class RAWIntTests:XCTestCase {
	func testAsRAWVal() throws {
		let value:Int = -512
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:value, count_out:&countout)
		#if arch(x86_64) || arch(arm64)
		let expectedBytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		#else
		let expectedBytes: [UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		#endif
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		#if arch(x86_64) || arch(arm64)
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		#else
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		#endif
		let value = Int(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, -512)
	}
}

// test that the UInt8 type is correctly converting to and from a raw representation.
class RAWInt8Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value:Int8 = -128
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:value, count_out:&countout)
		let expectedBytes: [UInt8] = [0x80]
		XCTAssertEqual(bytes, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x80]
		let value = Int8(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, -128)
	}
}

class RAWInt16Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: Int16 = -512
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:value, count_out:&countout)
		let expectedBytes: [UInt8] = [0xFE, 0x00]
		XCTAssertEqual(bytes, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFE, 0x00]
		let value = Int16(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, -512)
	}
}

class RAWInt32Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: Int32 = -512
		var countout:size_t = 0
		let bytes: [UInt8] = [UInt8](RAW_encodable:value, count_out:&countout)
		let expectedBytes:[UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		XCTAssertEqual(bytes, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		let expected = Int32(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(expected, -512)
	}
}

class RAWInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value:Int64 = -512
		var countout:size_t = 0
		let rawVal = [UInt8](RAW_encodable:value, count_out:&countout)
		let expectedBytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		let value = Int64(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, -512)
	}
}