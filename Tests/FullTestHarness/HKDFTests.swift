import XCTest
@testable import RAW_hkdf
import RAW_sha512
// import __crawdog_hmac_tests
import __crawdog_hkdf_tests

class HKDFTests: XCTestCase {
    func testHKDFExtract() throws {
        var salt = [UInt8]("someSalt".utf8)
        var ikm = [UInt8]("inputKeyMaterial".utf8)
        var expectedPRK = [UInt8](repeating: 0, count:RAW_sha512.Hasher.RAW_hasher_outputsize)
        
        var kdfState = crypto_kdf_hkdf_sha512_state()
		guard crypto_kdf_hkdf_sha512_extract_init(&kdfState, salt, salt.count) == 0 else {
			XCTFail("EXTRACT INIT FAIL.")
			return
		}

		guard crypto_kdf_hkdf_sha512_extract_update(&kdfState, ikm, ikm.count) == 0 else {
			XCTFail("EXTRACT UPDATE FAIL.")
			return
		}

		guard crypto_kdf_hkdf_sha512_extract_final(&kdfState, &expectedPRK) == 0 else {
			XCTFail("EXTRACT FINAL FAIL.")
			return
		}

		let resultPRK = try RAW_sha512.Hasher.hkdfExtract(salt:salt, ikm:ikm)
		XCTAssertEqual(resultPRK, expectedPRK, "EXTRACT FAIL.")
	}
}