import XCTest
@testable import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import cblake2

@StaticBufferType(5)
struct FixedBuff5 {}

// @ConcatBufferType(FixedBuff5, Double, Float)
// struct MYSTRUCT {
// 	// this is a test of comments in the struct. (they seem to work ok)
// 	let firstItem:FixedBuff5
// 	let secondItem:Double
// 	let thirdItem:Float
// }

// @ConcatBufferType(Double, Float)
// struct MYSTRUCT2 {
// 	private let firstItem:Double
// 	private let secondItem:Float
// }

@StaticBufferType(8)
struct MyUInt64Equivalent{}

@StaticBufferType(4)
struct MyUInt32Equivalent{}

@StaticBufferType(2)
struct MyUInt16Equivalent{}

final class TestDeveloperUsage:XCTestCase {
    func testDeveloperUseCase() {
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
		var blake2sHasher = try Blake2.S<FixedBuff5>()
		try blake2sHasher.update(Array("Hello".utf8))
		let blake2sHash = try blake2sHasher.finalize()
		let base64Decoded = try Base64.decode("HfZQsfk=")
		let asBuff = FixedBuff5(base64Decoded)!
		XCTAssertEqual(blake2sHash, asBuff)
	}

	// verifies that the size of a tuple is equal to the sum of the sizes of its members.
	func testLayeredSizingOfStaticStructs() {
		guard MemoryLayout<(FixedBuff5, FixedBuff5)>.size == 10 else {
			XCTFail("MemoryLayout<(FixedBuff5, FixedBuff5)>.size == \(MemoryLayout<(FixedBuff5, FixedBuff5)>.size)")
			return
		}

		guard MemoryLayout<(MyUInt16Equivalent, MyUInt32Equivalent, MyUInt64Equivalent)>.size == 14 else {
			XCTFail("MemoryLayout<(UInt16, UInt32, UInt64)>.size == \(MemoryLayout<(MyUInt16Equivalent, MyUInt32Equivalent, MyUInt64Equivalent)>.size)")
			return
		}
	}

	func testExpectedLengths() {
		XCTAssertEqual(BLAKE2B_OUTBYTES.rawValue, 64)
	}
}