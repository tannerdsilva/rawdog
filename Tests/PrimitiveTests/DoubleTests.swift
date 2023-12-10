import XCTest
@testable import RAW

final class NumberTests: XCTestCase {
	func testArrayEncodingAndDecoding() throws {
		let encodeNumbers:[Double] = [
			3.14159,
			3.0,
			3.141,
			-600
		]
		let decoded = encodeNumbers.asRAW_val { rawDat, rawSiz in
			XCTAssertEqual(rawSiz.pointee, 32)
			let bytes = Array<Double>(RAW_data:rawDat, RAW_size:rawSiz)
			return bytes
		}
		XCTAssertEqual(decoded, encodeNumbers)
	}
	func testEncodingAndDecodingDouble() throws {
		let value: Double = 3.14159
		let newVal = value.asRAW_val {
			return Double(RAW_data:$0, RAW_size:$1)
		}
		XCTAssertEqual(newVal, value)
	}
	func testEncodingAndDecodingFloat16() throws {
		let value: Float = 3.14159
		let newVal = value.asRAW_val {
			return Float(RAW_data:$0, RAW_size:$1)
		}
		XCTAssertEqual(newVal, value)
	}
}