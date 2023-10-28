import XCTest
@testable import RAW

final class NumberTests: XCTestCase {
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