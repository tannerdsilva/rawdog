import XCTest
import RAW_hex
import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import cblake2

@RAW_staticbuff(bytes:2)
struct MyFixeDThing {}

@RAW_staticbuff(bytes:5)
struct FixedBuff5:ExpressibleByArrayLiteral, Equatable {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_binaryfloatingpoint_type<Double>()
struct EncodedDouble:ExpressibleByFloatLiteral {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>()
struct EncodedFloat:ExpressibleByFloatLiteral {}

@RAW_staticbuff(concat:			FixedBuff5, 
								EncodedDouble,
								EncodedFloat,
								FixedBuff5)
struct MYSTRUCT {
	// this is a test of comments in the struct. (they seem to work ok)
	private var firstItem:FixedBuff5
	private var secondItem:EncodedDouble
	private var thirdItem:EncodedFloat
	private var fourthItem:FixedBuff5
}

@RAW_staticbuff(concat:EncodedDouble, EncodedFloat)
fileprivate struct MYSTRUCT2 {
	private var firstItem:EncodedDouble
	private var secondItem:EncodedFloat
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
struct MyUInt64Equivalent {}

@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
@RAW_staticbuff(bytes:4)
struct MyUInt32Equivalent {}

@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
@RAW_staticbuff(bytes:2)
struct MyUInt16Equivalent {}

@RAW_staticbuff(concat:MyUInt16Equivalent, MyUInt32Equivalent, MyUInt64Equivalent)
struct MySpecialUIntType {
	var bitVar16:MyUInt16Equivalent
	var bitVar32:MyUInt32Equivalent
	var bitVar64:MyUInt64Equivalent
}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
struct EncodedUInt64:ExpressibleByIntegerLiteral {}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
struct EncodedUInt32:ExpressibleByIntegerLiteral {}


// // mydually - this is used to test the linear sort and compare functions of the ConcatBufferType macro.
@RAW_staticbuff(concat:EncodedUInt64, EncodedUInt32)
struct MyDually {
	var first: EncodedUInt64
	var second: EncodedUInt32

	init(first:UInt64, second:UInt32) {
		self.first = EncodedUInt64(RAW_native:first)
		self.second = EncodedUInt32(RAW_native:second)
	}
}

extension MyDually:Comparable, Equatable {}


final class TestDeveloperUsage:XCTestCase {
	func testConcatMemoryLayout() {
		let myUInt64 = MyUInt64Equivalent(RAW_native:66)
		var myTest:FixedBuff5 = FixedBuff5(RAW_staticbuff:[0, 1, 2, 3, 4]) 
		let myTest2:FixedBuff5 = [0, 1, 2, 3, 4]
		// let it = myTest as! any RAW_staticbuff
		// let thing = myTest as! any ExpressibleByArrayLiteral
//		let thing2 = myTest as! any RAW_comparable_fixed
		// let fooBar:FixedBuff5 = "StringfTHing"
	}
	func testSortingByFirstVariable() {

		// XCTAssertTrue(EncodedUInt64.RAW_compare(lhs:5, rhs:10) < 0)

		let dually1 = MyDually(first: 10, second: 20)
		let dually2 = MyDually(first: 5, second: 30)

		XCTAssertTrue(dually2 < dually1, "\(dually2) < \(dually1)")

		let dually3 = MyDually(first: 15, second: 40)

		XCTAssertTrue(dually1 < dually3, "\(dually1) < \(dually3)")
		
		let sortedArray = [dually1, dually2, dually3].sorted()
		
		XCTAssertEqual(sortedArray, [dually2, dually1, dually3], "\(sortedArray)")
	}
	
	func testComparingByFirstVariable() {
		let dually1 = MyDually(first: 10, second: 20)
		let dually2 = MyDually(first: 5, second: 30)
		let dually3 = MyDually(first: 15, second: 40)
		
		XCTAssertTrue(dually1 > dually2, "\(dually1) < \(dually2)")
		XCTAssertFalse(dually2 > dually1, "\(dually2) < \(dually1)")
		XCTAssertTrue(dually1 < dually3, "\(dually1) < \(dually3)")
		XCTAssertFalse(dually3 < dually1, "\(dually3) < \(dually1)")
		XCTAssertTrue(dually2 < dually3, "\(dually2) < \(dually3)")
		XCTAssertFalse(dually3 < dually2, "\(dually3) < \(dually2)")
	}

	func testBlake2AndHexFunctionality() throws {
		do {
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
			XCTAssertGreaterThan(parsedJSON.count, 0)
			let testScenarios = try! JSONDecoder().decode([Blake2TestScenario].self, from:parsedJSON)
			XCTAssertGreaterThan(testScenarios.count, 512)
			for scenario in testScenarios {
				do {
					let keyData = try! RAW_hex.Encoded.from(encoded:scenario.key).decoded()
					let expectedBinaryOutput = try! RAW_hex.Encoded.from(encoded:scenario.output).decoded()
					let expectedBinaryInput = try! RAW_hex.Encoded.from(encoded:scenario.input).decoded()
					switch scenario.hash {
						case "blake2s":
							switch scenario.key.count {
								case 0:
									var b2sHasher = try Hasher<S, [UInt8]>(outputLength:expectedBinaryOutput.count)
									try b2sHasher.update(expectedBinaryInput)
									let b2sHash = try b2sHasher.finish()
									XCTAssertEqual(b2sHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2sHash))
									XCTAssertEqual(reenc_result, scenario.output)
								default:
									var b2sHasher = try Hasher<S, [UInt8]>(key_data:keyData, key_count:keyData.count, outputLength:expectedBinaryOutput.count)
									try b2sHasher.update(expectedBinaryInput)
									let b2sHash = try b2sHasher.finish()
									XCTAssertEqual(b2sHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2sHash))
									XCTAssertEqual(reenc_result, scenario.output)
							}
						case "blake2b":
							switch scenario.key.count {
								case 0:
									var b2bHasher = try Hasher<B, [UInt8]>(outputLength:expectedBinaryOutput.count)
									try b2bHasher.update(expectedBinaryInput)
									let b2bHash = try b2bHasher.finish()
									XCTAssertEqual(b2bHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2bHash))
									XCTAssertEqual(reenc_result, scenario.output)
								default:
									var b2bHasher = try Hasher<B, [UInt8]>(key_data:keyData, key_count:keyData.count, outputLength:expectedBinaryOutput.count)
									try b2bHasher.update(expectedBinaryInput)
									let b2bHash = try b2bHasher.finish()
									XCTAssertEqual(b2bHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2bHash))
									XCTAssertEqual(reenc_result, scenario.output)
							}
						case "blake2bp":
							switch scenario.key.count {
								case 0:
									var b2bpHasher = try Hasher<BP, [UInt8]>(outputLength:expectedBinaryOutput.count)
									try b2bpHasher.update(expectedBinaryInput)
									let b2bpHash = try b2bpHasher.finish()
									XCTAssertEqual(b2bpHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2bpHash))
									XCTAssertEqual(reenc_result, scenario.output)
								default:
									var b2bpHasher = try Hasher<BP, [UInt8]>(key_data:keyData, key_count:keyData.count, outputLength:expectedBinaryOutput.count)
									try b2bpHasher.update(expectedBinaryInput)
									let b2bpHash = try b2bpHasher.finish()
									XCTAssertEqual(b2bpHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2bpHash))
									XCTAssertEqual(reenc_result, scenario.output)
							}
						case "blake2sp":
							switch scenario.key.count {
								case 0:
									var b2spHasher = try Hasher<SP, [UInt8]>(outputLength:expectedBinaryOutput.count)
									try b2spHasher.update(expectedBinaryInput)
									let b2spHash = try b2spHasher.finish()
									XCTAssertEqual(b2spHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2spHash))
									XCTAssertEqual(reenc_result, scenario.output)
								default:
									var b2spHasher = try Hasher<SP, [UInt8]>(key_data:keyData, key_count:keyData.count, outputLength:expectedBinaryOutput.count)
									try b2spHasher.update(expectedBinaryInput)
									let b2spHash = try b2spHasher.finish()
									XCTAssertEqual(b2spHash, expectedBinaryOutput)
									let reenc_result = String(RAW_hex.Encoded.from(decoded:b2spHash))
									XCTAssertEqual(reenc_result, scenario.output)
							}
						default:
						break;
					}
				} catch let error {
					XCTFail("error: \(error)")
				}
			}
			var blake2sHasher = try Hasher<S, FixedBuff5>()
			try blake2sHasher.update(Array("Hello".utf8))
			var blake2sHash = try blake2sHasher.finish()
			var countout:size_t = 0
			let blake2sHashBytes = [UInt8](RAW_encodable:&blake2sHash, byte_count_out:&countout)
			let blake2sHashString = RAW_base64.encode(blake2sHashBytes)
			XCTAssertEqual(blake2sHashString, "HfZQsfk=")
			let b64Encoded:RAW_base64.Encoded = "HfZQsfk="
			let base64Decoded = b64Encoded.decoded()
			// let base64Decoded = try RAW_base64.decode("HfZQsfk=")
			let asBuff = FixedBuff5(RAW_decode:base64Decoded)!
			XCTAssertEqual(blake2sHash, asBuff)
		} catch let error {
			XCTFail("error: \(error)")
		}
	}
// }

	// verifies that the size of a tuple is equal to the sum of the sizes of its members.
	func testLayeredSizingOfStaticStructs() {
		guard MemoryLayout<(FixedBuff5, FixedBuff5)>.size == 10 else {
			XCTFail("MemoryLayout<(FixedBuff5, FixedBuff5)>.size == \(MemoryLayout<(FixedBuff5, FixedBuff5)>.size)")
			return
		}

		guard MemoryLayout<MySpecialUIntType>.size == 14 else {
			XCTFail("MemoryLayout<MySpecialUIntType>.size == \(MemoryLayout<MySpecialUIntType>.size)")
			return
		}

		guard MemoryLayout<MySpecialUIntType>.stride == 14 else {
			XCTFail("MemoryLayout<MySpecialUIntType>.stride == \(MemoryLayout<MySpecialUIntType>.stride)")
			return
		}
	}

	func testExpectedLengths() {
		XCTAssertEqual(BLAKE2B_OUTBYTES.rawValue, 64)
		XCTAssertEqual(BLAKE2S_OUTBYTES.rawValue, 32)
	}
}
