import XCTest
@testable import RAW


// test that the UInt type is correctly converting to and from a raw representation.
class RAWUIntTests:XCTestCase {
	func testAsRAWVal() throws {
		let value:UInt = 512
		let rawVal = [UInt8](RAW_encodable:value)
		#if arch(x86_64) || arch(arm64)
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		#else
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x02, 0x00]
		#endif
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		#if arch(x86_64) || arch(arm64)
		let bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		#else
		let bytes: [UInt8] = [0x00, 0x00, 0x02, 0x00]
		#endif
		let value = UInt(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, 512)
	}
}

// test that the UInt8 type is correctly converting to and from a raw representation.
class RAWUInt8Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt8 = 128
		let rawVal = [UInt8](RAW_encodable:value)
		let expectedBytes: [UInt8] = [0x80]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x80]
		let value = UInt8(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, 128)
	}
}

class RAWUInt16Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt16 = 512
		let rawVal = [UInt8](RAW_encodable:value)
		let expectedBytes: [UInt8] = [0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x02, 0x00]
		let value = UInt16(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, 512)
	}
}

class RAWUInt32Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt32 = 512
		let rawVal = [UInt8](RAW_encodable:value)
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x00, 0x00, 0x02, 0x00]
		let value = UInt32(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, 512)
	}
}

class RAWUInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value:UInt64 = 512
		let rawVal = [UInt8](RAW_encodable:value)
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		let value = UInt64(RAW_staticbuff_storetype:bytes)
		XCTAssertEqual(value, 512)
	}
}