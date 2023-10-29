import XCTest
@testable import RAW

final class NumberTests: XCTestCase {
	func testArrayEncodingAndDecoding() throws {
		var encodeNumbers:[any RAW_encodable] = [
			3.14159,
			3,
			3.141,
			5 as UInt8,
			99 as UInt64
		]
		let encoded = encodeNumbers.asRAW_val { rawVal in
			return Array<UInt8>(rawVal)
		}
		let decoded = Array<Double>(RAW_size:UInt64(encoded.count), RAW_data:encoded)
		XCTAssertEqual(decoded, encodeNumbers)
	}
    func testEncodingAndDecodingDouble() throws {
        let value: Double = 3.14159
        let newVal = value.asRAW_val {
			return Double(RAW_size: $0.RAW_size, RAW_data:$0.RAW_data)
		}
        XCTAssertEqual(newVal, value)
    }

	func testEncodingAndDecodingFloat16() throws {
		let value: Float16 = 3.14159
		let newVal = value.asRAW_val {
			return Float16(RAW_size: $0.RAW_size, RAW_data:$0.RAW_data)
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