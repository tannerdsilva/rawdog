// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import RAW

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_binaryfloatingpoint_type<Double>()
fileprivate struct _Double:Equatable, Sendable {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>()
fileprivate struct _Float:Sendable, Equatable {}

@Suite("RAW floating point macros")
struct NumberTests {
	@Test("@RAW_staticbuff_binaryfloatingpoint_type :: core")
	func testEncodingAndDecodingDouble() {
		for _ in 0..<5120 {
			var value:_Double = _Double(RAW_native:Double.random(in:0..<Double.greatestFiniteMagnitude))
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let newVal = _Double(RAW_decode:valueBytes)!
			#expect(newVal == value)
		}
	}
	@Test("@RAW_staticbuff_binaryfloatingpoint_type :: core")
	func testEncodingAndDecodingFloat() {
		for _ in 0..<5120 {
			var value:_Float = _Float(RAW_native:Float.random(in:0..<Float.greatestFiniteMagnitude))
			var countout:size_t = 0
			let valueBytes = [UInt8](RAW_encodable:&value, byte_count_out:&countout)
			let newVal = _Float(RAW_decode:valueBytes)!
			#expect(newVal == value)
		}
	}
}
