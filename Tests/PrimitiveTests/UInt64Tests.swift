import XCTest
@testable import RAW

class RAWUInt64Tests: XCTestCase {
	func testAsRAWVal() throws {
		let value: UInt64 = 1
		let rawVal = value.asRAW_val { rawDat, rawSiz in
			return Array<UInt8>(RAW_size:Int(rawSiz), RAW_data:rawDat)
		}
		let expectedBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
		XCTAssertEqual(rawVal, expectedBytes)
	}
    
    func testInitWithRAWData() {
        let bytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
        let value = UInt64(RAW_size:MemoryLayout<UInt64>.size, RAW_data:bytes)
        XCTAssertEqual(value, 1)
    }
}