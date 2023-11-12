import XCTest
@testable import RAW

class RAWUInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt64 = 1
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_data:rawDat, RAW_size:rawSiz)
		}
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
		XCTAssertEqual(rawVal, expectedBytes)
	}
	
	func testInitWithRAWData() {
		let bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
		withUnsafePointer(to:MemoryLayout<UInt64>.size) { sizePtr in
			let value = UInt64(RAW_data:bytes, RAW_size:sizePtr)
			XCTAssertEqual(value, 1)
		}
	}
}