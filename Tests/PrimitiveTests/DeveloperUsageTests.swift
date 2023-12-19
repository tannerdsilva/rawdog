import XCTest
@testable import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import cblake2
// import Foundation

@StaticBufferType(5, isUnsigned:true)
struct FixedBuff5 {}

// @ConcatBufferType(FixedBuff5, Double, Float)
// struct MYSTRUCT {
// 	// this is a test of comments in the struct. (they seem to work ok)
// 	let firstItem:FixedBuff5
// 	let secondItem:Double
// 	let thirdItem:Float
// }

@ConcatBufferType(Double, Float)
struct MYSTRUCT2 {
	let firstItem:Double
	let secondItem:Float
}

@StaticBufferType(8, isUnsigned:true)
struct MyUInt64Equivalent{}

@StaticBufferType(4, isUnsigned:true)
struct MyUInt32Equivalent{}

@StaticBufferType(2, isUnsigned:true)
struct MyUInt16Equivalent{}

@ConcatBufferType(MyUInt16Equivalent, MyUInt32Equivalent, MyUInt64Equivalent)
struct MySpecialUIntType {
	let bitVar16:MyUInt16Equivalent
	let bitVar32:MyUInt32Equivalent
	let bitVar64:MyUInt64Equivalent
}

final class TestDeveloperUsage:XCTestCase {
    func testDeveloperUseCase() {
		let myValues:[Value] = [.A, .F]
		myValues.asRAW_val { myValues, mySize in
			guard mySize.pointee == 2 else {
				XCTFail("mySize == \(mySize.pointee)")
				return
			}
			let myVal = val(RAW_data:myValues, RAW_size:mySize)
			guard myVal[0] == Value.A.rawValue else {
				XCTFail("myVal[0] == \(myVal[0])")
				return
			}
			guard myVal[1] == Value.F.rawValue else {
				XCTFail("myVal[1] == \(myVal[1])")
				return
			}
		}
		// var mything:#ByteTupleType(5)
		let myBaseData = [UInt8]("Hello".utf8)
		let mySecondBuff:FixedBuff5 = FixedBuff5(myBaseData)!
		let myThird = FixedBuff5(RAW_staticbuff_storetype:(0x48, 0x65, 0x6c, 0x6c, 0x6f))
		let myFourth:FixedBuff5 = [0x48, 0x65, 0x6c, 0x6c, 0x6f]

		XCTAssertEqual(mySecondBuff, myThird)
		XCTAssertEqual(mySecondBuff, myFourth)
		XCTAssertEqual(myThird, myFourth)

		// verify that each buffer is equal to the base
		for i in 0..<myBaseData.count {
			XCTAssertEqual(mySecondBuff[i], myBaseData[i])
			XCTAssertEqual(myThird[i], myBaseData[i])
			XCTAssertEqual(myFourth[i], myBaseData[i])
		}
	}


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
		var blake2sHasher = try Hasher<S, FixedBuff5>()
		try blake2sHasher.update(Array("Hello".utf8))
		let blake2sHash = try blake2sHasher.finish()
		let base64Decoded = try RAW_base64.decode("HfZQsfk=")
		let asBuff = FixedBuff5(base64Decoded)!
		XCTAssertEqual(blake2sHash, asBuff)
	}

	func testBlake2BOutBytes() {
		XCTAssertEqual(BLAKE2B_OUTBYTES.rawValue, 64)
	}

	// verifies that the size of a tuple is equal to the sum of the sizes of its members.
	func testLayeredSizingOfStaticStructs() {
		guard MemoryLayout<(FixedBuff5, FixedBuff5)>.size == 10 else {
			XCTFail("MemoryLayout<(FixedBuff5, FixedBuff5)>.size == \(MemoryLayout<(FixedBuff5, FixedBuff5)>.size)")
			return
		}

		guard MySpecialUIntType.RAW_staticbuff_size == 14 else {
			XCTFail("MySpecialUIntType.RAW_staticbuff_size == \(MySpecialUIntType.RAW_staticbuff_size)")
			return
		}
	}

	func testExpectedLengths() {
		XCTAssertEqual(BLAKE2B_OUTBYTES.rawValue, 64)
	}
}