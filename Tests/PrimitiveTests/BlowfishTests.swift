import XCTest
@testable import ccrypt_blowfish_tests
import RAW_hex

final class TestBlowfishHashing:XCTestCase {
	func testMainFunction() {
		guard crypt_test_swiftshim() == 0 else {
			XCTFail("ccrypt_blowfish_tests.testmainf() failed")
			return
		}
	}
}