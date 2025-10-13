// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import Foundation
import RAW_hex
import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import __crawdog_blake2
import __crawdog_argon2

@RAW_staticbuff(bytes:2)
struct MyFixeDThing:Sendable {}

extension MyFixeDThing:ExpressibleByArrayLiteral {
	@RAW_staticbuff(bytes:4)
	struct MyInnie:Sendable {}
} 

@RAW_staticbuff(bytes:5)
struct FixedBuff5:Sendable, ExpressibleByArrayLiteral, Equatable {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_binaryfloatingpoint_type<Double>()
struct EncodedDouble:Sendable, ExpressibleByFloatLiteral {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>()
struct EncodedFloat:Sendable, ExpressibleByFloatLiteral {}

@RAW_staticbuff(concat:			FixedBuff5.self, 
								EncodedDouble.self,
								EncodedFloat.self,
								FixedBuff5.self)
struct MYSTRUCT:Sendable {
	// this is a test of comments in the struct. (they seem to work ok)
	private var firstItem:FixedBuff5
	private var secondItem:EncodedDouble
	private var thirdItem:EncodedFloat
	private var fourthItem:FixedBuff5
}

@RAW_staticbuff(concat:			EncodedDouble.self,
								EncodedFloat.self)
fileprivate struct MYSTRUCT2:Sendable {
	private var firstItem:EncodedDouble
	private var secondItem:EncodedFloat

	fileprivate static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		var lhs = lhs_data.load(as:Self.self)
		var rhs = rhs_data.load(as:Self.self)
		let lastItemCompare = EncodedFloat.RAW_compare(lhs_data:&lhs.secondItem, rhs_data:&rhs.secondItem)
		if lastItemCompare != 0 {
			return lastItemCompare
		}
		return EncodedDouble.RAW_compare(lhs_data:&lhs.firstItem, rhs_data:&rhs.firstItem)
	}
}

@RAW_staticbuff(concat:MyFixeDThing.MyInnie.self)
struct MyInnieWrapper:Sendable {
	var innie:MyFixeDThing.MyInnie
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
struct MyUInt64Equivalent:Sendable {}

@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
@RAW_staticbuff(bytes:4)
struct MyUInt32Equivalent:Sendable {}

@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
@RAW_staticbuff(bytes:2)
struct MyUInt16Equivalent:Sendable {}

@RAW_staticbuff(concat:MyUInt16Equivalent.self, MyUInt32Equivalent.self, MyUInt64Equivalent.self)
struct MySpecialUIntType:Sendable {
	var bitVar16:MyUInt16Equivalent
	var bitVar32:MyUInt32Equivalent
	var bitVar64:MyUInt64Equivalent
	static let myComputedVar:String = "Hello"
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
struct EncodedUInt64:ExpressibleByIntegerLiteral, Sendable {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
struct EncodedUInt32:ExpressibleByIntegerLiteral, Sendable {}

// // mydually - this is used to test the linear sort and compare functions of the ConcatBufferType macro.
@RAW_staticbuff(concat:EncodedUInt64.self, EncodedUInt32.self)
struct MyDually:Sendable {
	var first: EncodedUInt64
	static let myThing:MyDually = MyDually(first: 10, second: 20)
	var second: EncodedUInt32

	init(first:UInt64, second:UInt32) {
		self.first = EncodedUInt64(RAW_native:first)
		self.second = EncodedUInt32(RAW_native:second)
	}
}

extension MyDually:Comparable, Equatable {}

extension rawdog_tests {
	@Suite("DeveloperUsageTests", .serialized)
	struct TestDeveloperUsage {
		@Test func testConcatMemoryLayout() {
			let _ = MyUInt64Equivalent(RAW_native:66)
			var _:FixedBuff5 = FixedBuff5(RAW_staticbuff:[0, 1, 2, 3, 4]) 
			let _:FixedBuff5 = [0, 1, 2, 3, 4]
		}

		@Test func testEntropyNoThrow() throws {
			let _ = try generateSecureRandomBytes(as:MySpecialUIntType.self)
		}
		@Test func testSortingByFirstVariable() {

			// XCTAssertTrue(EncodedUInt64.RAW_compare(lhs:5, rhs:10) < 0)

			let dually1 = MyDually(first: 10, second: 20)
			let dually2 = MyDually(first: 5, second: 30)

			#expect(dually2 < dually1, "\(dually2) < \(dually1)")

			let dually3 = MyDually(first: 15, second: 40)

			#expect(dually1 < dually3, "\(dually1) < \(dually3)")

			let sortedArray = [dually1, dually2, dually3].sorted()

			#expect(sortedArray == [dually2, dually1, dually3], "\(sortedArray)")
		}

		@Test func testComparingByFirstVariable() {
			let dually1 = MyDually(first: 10, second: 20)
			let dually2 = MyDually(first: 5, second: 30)
			let dually3 = MyDually(first: 15, second: 40)

			#expect(dually1 > dually2, "\(dually1) < \(dually2)")
			#expect((dually2 > dually1) == false, "\(dually2) < \(dually1)")
			#expect(dually1 < dually3, "\(dually1) < \(dually3)")
			#expect((dually3 < dually1) == false, "\(dually3) < \(dually1)")
			#expect(dually2 < dually3, "\(dually2) < \(dually3)")
			#expect((dually3 < dually2) == false, "\(dually3) < \(dually2)")
		}

		@Test func testBlake2AndHexFunctionality() throws {
			struct Blake2TestScenario:Codable {
				enum CodingKeys:String, CodingKey {
					case hash = "hash"
					case key = "key"
					case input = "in"
					case output = "out"
				}
				let hash:String
				let key:String
				let input:String
				let output:String
				init(from decoder:Decoder) throws {
					let container = try decoder.container(keyedBy:CodingKeys.self)
					hash = try container.decode(String.self, forKey:.hash)
					key = try container.decode(String.self, forKey:.key)
					input = try container.decode(String.self, forKey:.input)
					output = try container.decode(String.self, forKey:.output)
				}
				func encode(to encoder:Encoder) throws {
					var container = encoder.container(keyedBy:CodingKeys.self)
					try container.encode(hash, forKey:.hash)
					try container.encode(key, forKey:.key)
					try container.encode(input, forKey:.input)
					try container.encode(output, forKey:.output)
				}
			}
			let jsonTestContent = Bundle.module.resourceURL!.appendingPathComponent("blake2-kat.json")
			let parsedJSON = try Data(contentsOf:jsonTestContent)
			#expect(parsedJSON.count > 0)
			let testScenarios = try! JSONDecoder().decode([Blake2TestScenario].self, from:parsedJSON)
			#expect(testScenarios.count > 512)
			for scenario in testScenarios {
				let keyData = try RAW_hex.decode(scenario.key)
				let expectedBinaryOutput = try RAW_hex.decode(scenario.output)
				let expectedBinaryInput = try RAW_hex.decode(scenario.input)
				switch scenario.hash {
					case "blake2s":
						switch scenario.key.count {
							case 0:
								var b2sHasher = try Hasher<S, [UInt8]>(outputCount:expectedBinaryOutput.count)
								try b2sHasher.update(expectedBinaryInput)
								let b2sHash = try b2sHasher.finish()
								#expect(b2sHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2sHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2sHasher = try Hasher<S, [UInt8]>(key:keyData, outputCount:expectedBinaryOutput.count)
								try b2sHasher.update(expectedBinaryInput)
								let b2sHash = try b2sHasher.finish()
								#expect(b2sHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2sHash))
								#expect(reenc_result == scenario.output)
						}
					case "blake2b":
						switch scenario.key.count {
							case 0:
								var b2bHasher = try Hasher<B, [UInt8]>(outputCount:expectedBinaryOutput.count)
								try b2bHasher.update(expectedBinaryInput)
								let b2bHash = try b2bHasher.finish()
								#expect(b2bHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2bHasher = try Hasher<B, [UInt8]>(key:keyData, outputCount:expectedBinaryOutput.count)
								try b2bHasher.update(expectedBinaryInput)
								let b2bHash = try b2bHasher.finish()
								#expect(b2bHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bHash))
								#expect(reenc_result == scenario.output)
						}
					case "blake2bp":
						switch scenario.key.count {
							case 0:
								var b2bpHasher = try Hasher<BP, [UInt8]>(outputCount:expectedBinaryOutput.count)
								try b2bpHasher.update(expectedBinaryInput)
								let b2bpHash = try b2bpHasher.finish()
								#expect(b2bpHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bpHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2bpHasher = try Hasher<BP, [UInt8]>(key:keyData, outputCount:expectedBinaryOutput.count)
								try b2bpHasher.update(expectedBinaryInput)
								let b2bpHash = try b2bpHasher.finish()
								#expect(b2bpHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bpHash))
								#expect(reenc_result == scenario.output)
						}
					case "blake2sp":
						switch scenario.key.count {
							case 0:
								var b2spHasher = try Hasher<SP, [UInt8]>(outputCount:expectedBinaryOutput.count)
								try b2spHasher.update(expectedBinaryInput)
								let b2spHash = try b2spHasher.finish()
								#expect(b2spHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2spHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2spHasher = try Hasher<SP, [UInt8]>(key:keyData, outputCount:expectedBinaryOutput.count)
								try b2spHasher.update(expectedBinaryInput)
								let b2spHash = try b2spHasher.finish()
								#expect(b2spHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2spHash))
								#expect(reenc_result == scenario.output)
						}
					default:
					break;
				}
			}
			var blake2sHasher = try Hasher<S, FixedBuff5>()
			try blake2sHasher.update(Array("Hello".utf8))
			var blake2sHash = try blake2sHasher.finish()
			var countout:size_t = 0
			let blake2sHashBytes = [UInt8](RAW_encodable:&blake2sHash, byte_count_out:&countout)
			let blake2sHashString = RAW_base64.encode(blake2sHashBytes)
			#expect(blake2sHashString == "HfZQsfk=")
			let b64Encoded:RAW_base64.Encoded = "HfZQsfk="
			let base64Decoded = b64Encoded.decoded_data
			// let base64Decoded = try RAW_base64.decode("HfZQsfk=")
			let asBuff = FixedBuff5(RAW_decode:base64Decoded)!
			#expect(blake2sHash == asBuff)
		}

		// verifies that the size of a tuple is equal to the sum of the sizes of its members.
		@Test func testLayeredSizingOfStaticStructs() {
			#expect(MemoryLayout<(FixedBuff5, FixedBuff5)>.size == 10)

			#expect(MemoryLayout<MySpecialUIntType>.size == 14)

			#expect(MemoryLayout<MySpecialUIntType>.stride == 14)
		}

		@Test func testExpectedLengths() {
			#expect(__CRAWDOG_BLAKE2B_OUTBYTES.rawValue == 64)
			#expect(__CRAWDOG_BLAKE2S_OUTBYTES.rawValue == 32)
		}
		
		@RAW_staticbuff(bytes:64)
		struct MyLongStruct:Sendable {}
		
		@Test func testPointerComparisons() {
			let newStruct = MyLongStruct(RAW_staticbuff:MyLongStruct.RAW_staticbuff_zeroed())
			let firstBaseAddress = newStruct.RAW_access { pointer in
				return pointer.baseAddress!
			}
			let secondAddress = newStruct.RAW_access { pointer in
				return pointer.baseAddress!
			}
			#expect(firstBaseAddress == secondAddress)
		}

		@Test func testInvertedBits() {
			let my5 = ~FixedBuff5(RAW_staticbuff:FixedBuff5.RAW_staticbuff_zeroed())
			#expect(my5 == FixedBuff5(RAW_staticbuff:(255, 255, 255, 255, 255)))
		}
	}
}