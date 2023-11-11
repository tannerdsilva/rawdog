import XCTest
@testable import RAW

final class NumberTests: XCTestCase {
	func testArrayEncodingAndDecoding() throws {
		let encodeNumbers:[Double] = [
			3.14159,
			3.0,
			3.141,
		]
		let decoded = encodeNumbers.asRAW_val { rawVal in
			XCTAssertEqual(rawVal.RAW_size, 24)
			let bytes = Array<Double>(RAW_size:rawVal.RAW_size, RAW_data:rawVal.RAW_data)
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
			return Double(RAW_size: $0.RAW_size, RAW_data:$0.RAW_data)
		}
        XCTAssertEqual(newVal, value)
    }

	func testEncodingAndDecodingFloat16() throws {
		let value: Float = 3.14159
		let newVal = value.asRAW_val {
			return Float(RAW_size: $0.RAW_size, RAW_data:$0.RAW_data)
		}
		XCTAssertEqual(newVal, value)
	}

	func testEncodingAndDecodingUInt() throws {
		let value: UInt = 3
		let newVal = value.asRAW_val {
			return UInt(RAW_size: $0.RAW_size, RAW_data:$0.RAW_data)
		}
		XCTAssertEqual(newVal, value)
	}

	func testEncodingAndDecodingInt() throws {
		let value: Int = 3
		let newVal = value.asRAW_val {
			return Int(RAW_size: $0.RAW_size, RAW_data:$0.RAW_data)
		}
		XCTAssertEqual(newVal, value)
	}
}