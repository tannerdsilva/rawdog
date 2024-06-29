// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
import __crawdog_chachapoly_tests

final class chachapolyTests: XCTestCase {
    func testChachaPoly() throws {
        guard __crawdog_chachapoly_test_rfc7539() == 0 else {
        	fatalError("did not work bro")
        }
        guard __crawdog_chachapoly_test_auth_only() == 0 else {
        	fatalError("unit test fail :(")
        }
    }
}
