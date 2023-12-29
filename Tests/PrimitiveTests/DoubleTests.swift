import XCTest
@testable import RAW

final class NumberTests: XCTestCase {
	// func testArrayEncodingAndDecoding() throws {
	// 	let encodeNumbers:[Double] = [
	// 		3.14159,
	// 		3.0,
	// 		3.141,
	// 		-600
	// 	]
	// 	let decoded = [UInt8](RAW_encodables:encodeNumbers)
	// 	XCTAssertEqual(decoded, encodeNumbers)
	// }
	func testEncodingAndDecodingDouble() throws {
		let value: Double = 3.14159
		let valueBytes = [UInt8](RAW_encodable:value)
		let newVal = Double(RAW_staticbuff_storetype:valueBytes)
		XCTAssertEqual(newVal, value)
	}
	func testEncodingAndDecodingFloat16() throws {
		let value: Float = 3.14159
		let valueBytes = [UInt8](RAW_encodable:value)
		let newVal = Float(RAW_staticbuff_storetype:valueBytes)
		XCTAssertEqual(newVal, value)
	}
}