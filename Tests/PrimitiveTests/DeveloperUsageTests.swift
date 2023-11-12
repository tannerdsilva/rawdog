import XCTest
@testable import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import cblake2

@StaticBufferType(5)
struct FixedBuff5 {}

@ConcatBufferType(FixedBuff5, FixedBuff5)
struct MYSTRUCT {
	let mYThing:FixedBuff5
	let secondThing:FixedBuff5
}

final class TestDeveloperUsage:XCTestCase {
    func testDeveloperUseCase() {
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

	func testExpectedLengths() {
		XCTAssertEqual(BLAKE2B_OUTBYTES.rawValue, 64)
	}
}