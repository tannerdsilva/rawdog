import XCTest
@testable import RAW


// test that the UInt type is correctly converting to and from a raw representation.
class RAWUIntTests:XCTestCase {
	func testAsRAWVal() throws {
		let value:UInt = 512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
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
		withUnsafePointer(to:MemoryLayout<Int>.size) { sizePtr in
			let value = UInt(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, 512)
		}
	}
}

// test that the UInt8 type is correctly converting to and from a raw representation.
class RAWUInt8Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt8 = 128
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0x80]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x80]
		withUnsafePointer(to:MemoryLayout<UInt8>.size) { sizePtr in
			let value = UInt8(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, 128)
		}
	}
}

class RAWUInt16Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt16 = 512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x02, 0x00]
		withUnsafePointer(to:MemoryLayout<UInt16>.size) { sizePtr in
			let value = UInt16(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, 512)
		}
	}
}

class RAWUInt32Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt32 = 512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x00, 0x00, 0x02, 0x00]
		withUnsafePointer(to:MemoryLayout<UInt32>.size) { sizePtr in
			let value = UInt32(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, 512)
		}
	}
}

class RAWUInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value:UInt64 = 512
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00]
		withUnsafePointer(to:MemoryLayout<UInt64>.size) { sizePtr in
			let value = UInt64(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, 512)
		}
	}
}