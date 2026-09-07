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

@RAW_staticbuff(bytes:5)
struct FixedBuff5:Sendable, Equatable, RAW_decodable {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_binaryfloatingpoint_type<Double>()
struct EncodedDouble:RAW_native, Sendable {
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>()
struct EncodedFloat:RAW_native, Sendable {
}

@RAW_staticbuff(concat:FixedBuff5.self, EncodedDouble.self, EncodedFloat.self, FixedBuff5.self)
struct MYSTRUCT:Sendable {}

@RAW_staticbuff(concat:EncodedDouble.self, EncodedFloat.self)
fileprivate struct MYSTRUCT2:Sendable {}

@RAW_staticbuff(concat:MyFixeDThing.self)
struct MyInnieWrapper:Sendable {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
struct MyUInt64Equivalent:Sendable, RAW_native {
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
struct MyUInt32Equivalent:Sendable, RAW_native {
}

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
struct MyUInt16Equivalent:Sendable, RAW_native {
}

@RAW_staticbuff(concat:MyUInt16Equivalent.self, MyUInt32Equivalent.self, MyUInt64Equivalent.self)
struct MySpecialUIntType:Sendable {}

@RAW_staticbuff(bytes:8)
@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
struct EncodedUInt64:Sendable, RAW_native {
}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
struct EncodedUInt32:Sendable, RAW_native {
}

@RAW_staticbuff(concat:EncodedUInt64.self, EncodedUInt32.self)
struct MyDually:Sendable {}

extension MyDually:Comparable, Equatable {}

extension rawdog_tests {
	@Suite("DeveloperUsageTests", .serialized)
	struct TestDeveloperUsage {
		@Test func testConcatMemoryLayout() {
			let _ = MyUInt64Equivalent(RAW_native:66)
		}

		@Test func testEntropyNoThrow() throws {
			let _ = try generateSecureRandomBytes(count: MemoryLayout<MySpecialUIntType>.size)
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
								var b2sHasher = try Hasher<S, [UInt8]>(outputLength:expectedBinaryOutput.count)
								try b2sHasher.update(expectedBinaryInput)
								let b2sHash = try b2sHasher.finish()
								#expect(b2sHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2sHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2sHasher = try Hasher<S, [UInt8]>(key:keyData, outputLength:expectedBinaryOutput.count)
								try b2sHasher.update(expectedBinaryInput)
								let b2sHash = try b2sHasher.finish()
								#expect(b2sHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2sHash))
								#expect(reenc_result == scenario.output)
						}
					case "blake2b":
						switch scenario.key.count {
							case 0:
								var b2bHasher = try Hasher<B, [UInt8]>(outputLength:expectedBinaryOutput.count)
								try b2bHasher.update(expectedBinaryInput)
								let b2bHash = try b2bHasher.finish()
								#expect(b2bHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2bHasher = try Hasher<B, [UInt8]>(key:keyData, outputLength:expectedBinaryOutput.count)
								try b2bHasher.update(expectedBinaryInput)
								let b2bHash = try b2bHasher.finish()
								#expect(b2bHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bHash))
								#expect(reenc_result == scenario.output)
						}
					case "blake2bp":
						switch scenario.key.count {
							case 0:
								var b2bpHasher = try Hasher<BP, [UInt8]>(outputLength:expectedBinaryOutput.count)
								try b2bpHasher.update(expectedBinaryInput)
								let b2bpHash = try b2bpHasher.finish()
								#expect(b2bpHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bpHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2bpHasher = try Hasher<BP, [UInt8]>(key:keyData, outputLength:expectedBinaryOutput.count)
								try b2bpHasher.update(expectedBinaryInput)
								let b2bpHash = try b2bpHasher.finish()
								#expect(b2bpHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2bpHash))
								#expect(reenc_result == scenario.output)
						}
					case "blake2sp":
						switch scenario.key.count {
							case 0:
								var b2spHasher = try Hasher<SP, [UInt8]>(outputLength:expectedBinaryOutput.count)
								try b2spHasher.update(expectedBinaryInput)
								let b2spHash = try b2spHasher.finish()
								#expect(b2spHash == expectedBinaryOutput)
								let reenc_result = String(RAW_hex.encode(b2spHash))
								#expect(reenc_result == scenario.output)
							default:
								var b2spHasher = try Hasher<SP, [UInt8]>(key:keyData, outputLength:expectedBinaryOutput.count)
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
			var blake2sHasher = try Hasher<S, [UInt8]>(outputLength:5)
			try blake2sHasher.update(Array("Hello".utf8))
			var blake2sHash = try blake2sHasher.finish()
			var countout:Int = 0
			let blake2sHashBytes = [UInt8](RAW_encodable:&blake2sHash, byte_count_out:&countout)
			let blake2sHashString = RAW_base64.encode(blake2sHashBytes)
			#expect(blake2sHashString == "HfZQsfk=")
			let b64Encoded:RAW_base64.Encoded = "HfZQsfk="
			let base64Decoded = b64Encoded.decoded_data
			#expect(blake2sHash == base64Decoded)
		}

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
			let newStruct = [UInt8](repeating: 0, count: 64).withUnsafeBytes { MyLongStruct(RAW_decode: $0)! }
			let firstBaseAddress = newStruct.RAW_access_immutable(UnsafeRawBufferPointer.self) { pointer in
				return pointer.baseAddress!
			}
			let secondAddress = newStruct.RAW_access_immutable(UnsafeRawBufferPointer.self) { pointer in
				return pointer.baseAddress!
			}
			#expect(firstBaseAddress == secondAddress)
		}
	}
}
