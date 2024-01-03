import XCTest
import RAW_hex
@testable import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import cblake2
// import Foundation

@RAW_staticbuff(5, isUnsigned:true)
struct FixedBuff5:Hashable, Equatable, Collection, Sequence, ExpressibleByArrayLiteral {
	static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
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
struct MYSTRUCT2 {
	let firstItem:Double
	let secondItem:Float
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
	func testBlake2Functionality() throws {
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
		let testScenarios = try JSONDecoder().decode([Blake2TestScenario].self, from:parsedJSON)
		var buildHashes = [String:[Blake2TestScenario]]()
		for scenario in testScenarios {
			let inputData = scenario.input
			let keyData = scenario.key
			switch scenario.hash {
				case "blake2s":
					let b2sHasher = try Hasher<S, [UInt8]>(key:keyData, keySize:keyData.count, outputLength:32)
	
					default:
					break;

			}
		}
		var blake2sHasher = try Hasher<S, FixedBuff5>()
		try blake2sHasher.update(Array("Hello".utf8))
		let blake2sHash = try blake2sHasher.finish()
		let blake2sHashBytes = [UInt8](RAW_encodable:blake2sHash)
		let blake2sHashString = try RAW_base64.encode(bytes:blake2sHashBytes)
		XCTAssertEqual(blake2sHashString, "HfZQsfk=")
		let b64Encoded = try RAW_base64.Encoded(validate:"HfZQsfk=")
		let base64Decoded = try b64Encoded.decoded()
		// let base64Decoded = try RAW_base64.decode("HfZQsfk=")
		let asBuff = FixedBuff5(RAW_decode:base64Decoded)!
		XCTAssertEqual(blake2sHash, asBuff)
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
