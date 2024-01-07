import XCTest
import RAW_hex
@testable import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import cblake2

@RAW_staticbuff(5, isUnsigned:true)
struct FixedBuff5:Hashable, Equatable, Collection, Sequence, ExpressibleByArrayLiteral {
	internal static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		return RAW_memcmp(lhs_data, rhs_data, 5)
	}
}

@ConcatBufferType(FixedBuff5, Double, Float)
struct MYSTRUCT {
	// this is a test of comments in the struct. (they seem to work ok)
	let firstItem:FixedBuff5
	let secondItem:Double
	let thirdItem:Float
}

@ConcatBufferType(Double, Float)
fileprivate struct MYSTRUCT2 {
	internal let firstItem:Double
	internal let secondItem:Float
}

@RAW_staticbuff(8, isUnsigned:true)
struct MyUInt64Equivalent {}

@RAW_staticbuff(4, isUnsigned:true)
struct MyUInt32Equivalent {}

@RAW_staticbuff(2, isUnsigned:true)
struct MyUInt16Equivalent {}

@ConcatBufferType(MyUInt16Equivalent, MyUInt32Equivalent, MyUInt64Equivalent)
struct MySpecialUIntType {
	let bitVar16:MyUInt16Equivalent
	let bitVar32:MyUInt32Equivalent
	let bitVar64:MyUInt64Equivalent
}

final class TestDeveloperUsage:XCTestCase {
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
									var b2sHasher = try Hasher<S, [UInt8]>(key:keyData, keySize:keyData.count, outputLength:expectedBinaryOutput.count)
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
									var b2bHasher = try Hasher<B, [UInt8]>(key:keyData, keySize:keyData.count, outputLength:expectedBinaryOutput.count)
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
									var b2bpHasher = try Hasher<BP, [UInt8]>(key:keyData, keySize:keyData.count, outputLength:expectedBinaryOutput.count)
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
									var b2spHasher = try Hasher<SP, [UInt8]>(key:keyData, keySize:keyData.count, outputLength:expectedBinaryOutput.count)
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
			let blake2sHash = try blake2sHasher.finish()
			var countout:size_t = 0
			let blake2sHashBytes = [UInt8](RAW_encodable:blake2sHash, count_out:&countout)
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
