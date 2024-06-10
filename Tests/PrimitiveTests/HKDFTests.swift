import XCTest
@testable import RAW_hkdf  // Make sure to import your module
import RAW_sha256
import __crawdog_hkdf_tests  // Import the bridging header

class HKDFTests: XCTestCase {
    func testHKDFExtract() throws {
        var salt = [UInt8]("someSalt".utf8)
        var ikm = [UInt8]("inputKeyMaterial".utf8)
        var expectedPRK = [UInt8](repeating: 0, count:RAW_sha256.Hasher.RAW_hasher_outputsize)
        
        let _ = _libsodiumREF_hkdf_extract(&salt, salt.count, &ikm, ikm.count, &expectedPRK)

        let resultPRK = try RAW_sha256.Hasher.hkdfExtract(salt: salt, ikm: ikm)
        XCTAssertEqual(resultPRK, expectedPRK, "PRK does not match expected output.")

		var prk = resultPRK
        var info = [UInt8]("infoString".utf8)
        let outputLength = 32
        var expectedOKM = [UInt8](repeating: 0, count: outputLength)
        
        let _ = _libsodiumREF_hkdf_expand(&prk, &info, info.count, &expectedOKM, outputLength)

        let resultOKM = try RAW_sha256.Hasher.hkdfExpand(prk: prk, info: info, len: outputLength)
        XCTAssertEqual(resultOKM, expectedOKM, "OKM does not match expected output.")    }

    func testHKDFExpand() throws {
        
    }
}