// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
@testable import __crawdog_crypt_blowfish_tests
import RAW_hex

final class TestBlowfishHashing:XCTestCase {
	func testMainFunction() {
		guard __crawdog_crypt_test_swiftshim() == 0 else {
			XCTFail("ccrypt_blowfish_tests.testmainf() failed")
			return
		}
	}
}