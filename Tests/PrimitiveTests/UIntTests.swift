import XCTest
@testable import RAW


// test that the UInt type is correctly converting to and from a raw representation.
class RAWIntTests:XCTestCase {
	func testAsRAWVal() throws {
		let value:Int = -512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
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
		withUnsafePointer(to:MemoryLayout<Int>.size) { sizePtr in
			let value = Int(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, -512)
		}
	}
}

// test that the UInt8 type is correctly converting to and from a raw representation.
class RAWInt8Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value:Int8 = -128
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0x80]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x80]
		withUnsafePointer(to:MemoryLayout<Int8>.size) { sizePtr in
			let value = Int8(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, -128)
		}
	}
}

class RAWInt16Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: Int16 = -512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0xFE, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFE, 0x00]
		withUnsafePointer(to:MemoryLayout<Int16>.size) { sizePtr in
			let value = Int16(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, -512)
		}
	}
}

class RAWInt32Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: Int32 = -512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes:[UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFE, 0x00]
		withUnsafePointer(to:MemoryLayout<Int32>.size) { sizePtr in
			let value = Int32(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, -512)
		}
	}
}

class RAWInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value:Int64 = -512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x00]
		withUnsafePointer(to:MemoryLayout<UInt64>.size) { sizePtr in
			let value = Int64(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, -512)
		}
	}
}