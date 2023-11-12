import XCTest
@testable import RAW

final class NumberTests: XCTestCase {
	func testArrayEncodingAndDecoding() throws {
		let encodeNumbers:[Double] = [
			3.14159,
			3.0,
			3.141,
		]
		let decoded = encodeNumbers.asRAW_val { rawDat, rawSiz in
			XCTAssertEqual(Int(rawSiz), 24)
			let bytes = Array<Double>(RAW_size:Int(rawSiz), RAW_data:rawDat)
			return bytes
		}
		XCTAssertEqual(decoded, [
			3.14159,
			3,
			3.141
		])
	}
	func testEncodingAndDecodingDouble() throws {
		let value: Double = 3.14159
		let newVal = value.asRAW_val {
			return Double(RAW_size:Int($1), RAW_data:$0)
		}
		XCTAssertEqual(newVal, value)
	}
	func testEncodingAndDecodingFloat16() throws {
		let value: Float = 3.14159
		let newVal = value.asRAW_val {
			return Float(RAW_size:Int($1), RAW_data:$0)
		}
		XCTAssertEqual(newVal, value)
	}

	func testEncodingAndDecodingUInt() throws {
		let value: UInt = 3
		let newVal = value.asRAW_val {
			return UInt(RAW_size:Int($1), RAW_data:$0)
		}
		XCTAssertEqual(newVal, value)
	}

	func testEncodingAndDecodingInt() throws {
		let value: Int = 3
		let newVal = value.asRAW_val {
			return Int(RAW_size:Int($1), RAW_data:$0)
		}
		XCTAssertEqual(newVal, value)
	}
}