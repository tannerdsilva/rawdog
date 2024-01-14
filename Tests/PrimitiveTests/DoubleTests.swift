import XCTest
import RAW

@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bits:32, bigEndian:true)
fileprivate struct _UInt32:ExpressibleByIntegerLiteral, Equatable, Comparable {}

@RAW_staticbuff_binaryfloatingpoint_type<Double>()
fileprivate struct _Double:ExpressibleByFloatLiteral, Equatable, Comparable {}

@RAW_staticbuff_binaryfloatingpoint_type<Float>()
fileprivate struct _Float:ExpressibleByFloatLiteral, Equatable, Comparable {}


final class NumberTests:XCTestCase {

	func testEncodingAndDecodingDouble() throws {
		for _ in 0..<5120 {
			let value: _Double = _Double(Double.random(in:0..<Double.greatestFiniteMagnitude))
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:value, count_out:&countout)
			let newVal = _Double(RAW_decode:valueBytes)!
			XCTAssertEqual(newVal, value)
		}
	}
	func testEncodingAndDecodingFloat() throws {
		for _ in 0..<5120 {
			let value: _Float = _Float(Float.random(in:0..<Float.greatestFiniteMagnitude))
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:value, count_out:&countout)
			let newVal = _Float(RAW_decode:valueBytes)!
			XCTAssertEqual(newVal, value)
		}
	}
}