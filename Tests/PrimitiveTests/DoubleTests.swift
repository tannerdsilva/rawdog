import XCTest
@testable import RAW

final class NumberTests:XCTestCase {
	func testArray() throws {
		typealias TestType = UInt32
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
		for _ in 0..<5120 {
			let value: Double = Double.random(in:0..<Double.greatestFiniteMagnitude)
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:value, count_out:&countout)
			let newVal = Double(RAW_staticbuff_storetype:valueBytes)
			XCTAssertEqual(newVal, value)
		}
	}
	func testEncodingAndDecodingFloat() throws {
		for _ in 0..<5120 {
			let value: Float = Float.random(in:0..<Float.greatestFiniteMagnitude)
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:value, count_out:&countout)
			let newVal = Float(RAW_staticbuff_storetype:valueBytes)
			XCTAssertEqual(newVal, value)
		}
	}
}