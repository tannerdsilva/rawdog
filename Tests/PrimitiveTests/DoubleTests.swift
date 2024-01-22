import XCTest
import RAW

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
fileprivate struct _UInt32:Equatable {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_binaryfloatingpoint_type<Double>()
fileprivate struct _Double:Equatable {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>()
fileprivate struct _Float:Equatable {}


final class NumberTests:XCTestCase {

	func testEncodingAndDecodingDouble() throws {
		for _ in 0..<5120 {
			var value:_Double = _Double(RAW_native:Double.random(in:0..<Double.greatestFiniteMagnitude))
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let newVal = _Double(RAW_decode:valueBytes)!
			XCTAssertEqual(newVal, value)
		}
	}
	func testEncodingAndDecodingFloat() throws {
		for _ in 0..<5120 {
			var value:_Float = _Float(RAW_native:Float.random(in:0..<Float.greatestFiniteMagnitude))
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let newVal = _Float(RAW_decode:valueBytes)!
			XCTAssertEqual(newVal, value)
		}
	}
}
