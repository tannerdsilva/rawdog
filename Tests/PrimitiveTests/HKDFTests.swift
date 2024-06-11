// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
@testable import RAW_kdf  // Make sure to import your module
import RAW_sha256
import __crawdog_kdf_tests

class HKDFTests: XCTestCase {
    func testHKDF() throws {
        var salt = [UInt8]("someSalt".utf8)
        var ikm = [UInt8]("inputKeyMaterial".utf8)
        let expectedPRK = UnsafeMutablePointer<UInt8>.allocate(capacity:RAW_sha256.Hasher.RAW_hasher_outputsize)
        
        var kdfState = crypto_kdf_hkdf_sha256_state()
		guard crypto_kdf_hkdf_sha256_extract_init(&kdfState, salt, salt.count) == 0 else {
			XCTFail("EXTRACT INIT FAIL.")
			return
		}

		guard crypto_kdf_hkdf_sha256_extract_update(&kdfState, ikm, ikm.count) == 0 else {
			XCTFail("EXTRACT UPDATE FAIL.")
			return
		}

		guard crypto_kdf_hkdf_sha256_extract_final(&kdfState, expectedPRK) == 0 else {
			XCTFail("EXTRACT FINAL FAIL.")
			return
		}

		let resultPRK = try RAW_sha256.Hasher.hkdfExtract(salt: salt, ikm: ikm)
		XCTAssertEqual(resultPRK, [UInt8](RAW_decode:expectedPRK, count:RAW_sha256.Hasher.RAW_hasher_outputsize), "EXTRACT FAIL.")
	}
	
	func testHKDFExtract() throws {
		var salt = [UInt8]("someSalt".utf8)
		var ikm = [UInt8]("inputKeyMaterial".utf8)
		var expectedPRK = [UInt8](repeating: 0, count:RAW_sha256.Hasher.RAW_hasher_outputsize)
		
		var kdfState = crypto_kdf_hkdf_sha512_state()

		return
        let resultPRK = try RAW_sha256.Hasher.hkdfExtract(salt: salt, ikm: ikm)
        XCTAssertEqual(resultPRK, expectedPRK, "EXTRACT FAIL.")
	}
	
	// func testHKDFExpand() throws {
	// 	var prk = [UInt8](repeating: 0, count:RAW_sha256.Hasher.RAW_hasher_outputsize)
    //     var info = [UInt8]("infoString".utf8)
    //     let outputLength = 32
    //     var expectedOKM = [UInt8](repeating: 0, count: outputLength)
        
    //     let _ = _libsodiumREF_hkdf_expand(&prk, &info, info.count, &expectedOKM, outputLength)

    //     let resultOKM = try RAW_sha256.Hasher.hkdfExpand(prk: prk, info: info, len: outputLength)
    //     XCTAssertEqual(resultOKM, expectedOKM, "EXPAND FAIL")
    // }
}