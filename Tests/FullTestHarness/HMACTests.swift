import XCTest
import __crawdog_hmac_tests
@testable import RAW_sha1
@testable import RAW_hmac
import RAW_hex
import RAW

@RAW_staticbuff(bytes: 20)
fileprivate struct SHA1Hash:Sendable {}

class HMACSHA1Tests: XCTestCase {
    
    func testHMACSHA1() throws {
        for _ in 0..<10 { // Run 10 tests
            try runSingleTest()
        }
    }

    var failures = [(String, String, String)]()

    func runSingleTest() throws {
        let key = randomBytes(count: 20)
        let msg: [UInt8] = randomBytes(count: 20)
        let resultingOutput = String(RAW_hex.encode(try hmacSHA1(key: key, message: msg)))
        let referenceOutput = String(RAW_hex.encode(performHMACSHA1WithC(key: key, message: msg)))
		
		XCTAssertEqual(resultingOutput, referenceOutput)
    }

    func performHMACSHA1WithC(key: [UInt8], message: [UInt8]) -> [UInt8] {
        var output = [UInt8](repeating: 0, count: 20) // SHA1 output is always 20 bytes
        hmac_sha1(key, UInt32(key.count), message, UInt32(message.count), &output)
        return output 
    }

	fileprivate func hmacSHA1(key: [UInt8], message: [UInt8]) throws -> [UInt8] {
		var hmac = try HMAC<RAW_sha1.Hasher<SHA1Hash>>(key: key)
		try hmac.update(message:message)
		return try hmac.finish().RAW_access({
			return [UInt8](RAW_decode:$0.baseAddress!, count:$0.count)
		})
	}

    func randomBytes(count: Int) -> [UInt8] {
        return (0..<count).map { _ in UInt8.random(in: 0...255) }
    }
}