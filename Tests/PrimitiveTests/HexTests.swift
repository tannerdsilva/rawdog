import XCTest
import CRAW_hex

class HexTests: XCTestCase {
	func testHexDecode() {
		let hexString = "1F2F"
		let expectedData: [UInt8] = [0x1F, 0x2F]
		var decodedData = [UInt8](repeating: 0, count: expectedData.count)
		
		let result = hex_decode(hexString, hexString.count, &decodedData, decodedData.count)
		
		XCTAssertTrue(result)
		XCTAssertEqual(decodedData, expectedData)
	}
	
	func testHexEncode() {
		let data: [UInt8] = [0x1F, 0x2F]
		let expectedHexString = "1F2F"
		var encodedString = [CChar](repeating: 0, count: expectedHexString.count + 1)
		
		let result = hex_encode(data, data.count, &encodedString, encodedString.count)
		
		XCTAssertTrue(result)
		XCTAssertEqual(String(cString: encodedString), expectedHexString)
	}
	
	func testHexStrSize() {
		let dataSize = 5
		let expectedSize = 2 * dataSize + 1
		
		let result = hex_str_size(dataSize)
		
		XCTAssertEqual(result, expectedSize)
	}
	
	func testHexDataSize() {
		let hexString = "1F2F"
		let expectedSize = hexString.count / 2
		
		let result = hex_data_size(hexString.count)
		
		XCTAssertEqual(result, expectedSize)
	}
}