import XCTest
@testable import RAW

@StaticBufferType(5)
struct FixedBuff5:RAW_comparable {}

@StaticBufferType(8)
struct FixedBuff8:RAW_comparable {}

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
}