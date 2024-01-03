import XCTest
@testable import RAW_hex

class HexTests: XCTestCase {
	func testHexDecode() throws {
		let hexString:Encoded = "1F2F"
		let expectedData: [Value] = [.one, .f, .two, .f]
		
		let result = try Decode.process(values:expectedData, value_size:expectedData.count)
		
		// XCTAssertTrue(result)
		XCTAssertEqual(result, [0x1F, 0x2F])
		XCTAssertEqual(try Array<Value>(validate:String(hexString)), expectedData)
	}

	func testEncodedHexRandomAccessTest() throws {
		let hexString:Encoded = "1F2F"
		let expectedData: [Value] = [.one, .f, .two, .f]
		// XCTAssertEqual(hexString)
		for (index, value) in hexString.enumerated() {
			XCTAssertEqual(hexString[index], expectedData[index].characterValue())
		}
	}
	
	// func testHexEncode() {
	// 	let data: [UInt8] = [0x1F, 0x2F]
	// 	let expectedHexString = "1F2F"
	// 	var encodedString = [CChar](repeating: 0, count: expectedHexString.count + 1)
		
	// 	let result = hex_encode(data, data.count, &encodedString, encodedString.count)
		
	// 	XCTAssertTrue(result)
	// 	XCTAssertEqual(String(cString: encodedString), expectedHexString)
	// }
	
	// func testHexStrSize() {
	// 	let dataSize = 5
	// 	let expectedSize = 2 * dataSize + 1
		
	// 	let result = hex_str_size(dataSize)
		
	// 	XCTAssertEqual(result, expectedSize)
	// }
	
	// func testHexDataSize() {
	// 	let hexString = "1F2F"
	// 	let expectedSize = hexString.count / 2
		
	// 	let result = hex_data_size(hexString.count)
		
	// 	XCTAssertEqual(result, expectedSize)
	// }
}