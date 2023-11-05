import XCTest
@testable import RAW
@testable import RAW_blake2
@testable import RAW_base64
@testable import cblake2

@StaticBufferType(5)
struct FixedBuff5:RAW_comparable {}

final class TestDeveloperUsage:XCTestCase {
    func testDeveloperUseCase() {
		let myBaseData = [UInt8]("Hello".utf8)
		let mySecondBuff:FixedBuff5 = FixedBuff5(myBaseData)!
		let myThird = FixedBuff5((0x48, 0x65, 0x6c, 0x6c, 0x6f))

		XCTAssertEqual(mySecondBuff, myThird)
		// verify that each buffer is equal to the base
		for i in 0..<4 {
			XCTAssertEqual(mySecondBuff[i], myBaseData[i])
			XCTAssertEqual(myThird[i], myBaseData[i])
		}
	}

	func testBlake2Functionality() throws {
		var blake2sHasher = try Blake2.S<FixedBuff5>()
		try blake2sHasher.update(Array("Hello".utf8))
		let blake2sHash = try blake2sHasher.finalize()
		XCTAssertEqual(blake2sHash, FixedBuff5(try! Base64.decode("HfZQsfk="))!)
	}

	func testExpectedLengths() {
		XCTAssertEqual(BLAKE2B_OUTBYTES.rawValue, 64)
	}
}