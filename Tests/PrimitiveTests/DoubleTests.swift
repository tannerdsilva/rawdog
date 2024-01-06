import XCTest
@testable import RAW

final class NumberTests:XCTestCase {
	func testArray() throws {
		typealias TestType = UInt64
		var makeDouble = [TestType]()
		for _ in 0..<5120 {
			// add a random value to the array
			withUnsafePointer(to:(
				UInt8.random(in:0..<255),
				UInt8.random(in:0..<255),
				UInt8.random(in:0..<255),
				UInt8.random(in:0..<255),

				UInt8.random(in:0..<255),
				UInt8.random(in:0..<255),
				UInt8.random(in:0..<255),
				UInt8.random(in:0..<255)
			)) {
				let doubleValue = TestType(RAW_staticbuff_storetype:$0)
				makeDouble.append(doubleValue)
			}
		}
		let sortedItems = makeDouble.sorted(by: { TestType.RAW_compare(lhs:$0, rhs:$1) < 0 })
		let nativeSort = makeDouble.sorted(by: { $0 < $1 })
		XCTAssertEqual(sortedItems, nativeSort)
	}

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