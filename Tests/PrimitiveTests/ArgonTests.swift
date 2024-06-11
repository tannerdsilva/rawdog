// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
import __crawdog_argon2

class Argon2Tests: XCTestCase {
	static func hashTest(version:UInt32, threadCount:UInt32, memoryCount:UInt32, parallelismCount:UInt32, pwd:UnsafeMutableBufferPointer<UInt8>, salt:UnsafeMutableBufferPointer<UInt8>, hexRef:UnsafeMutableBufferPointer<UInt8>, mcRef:UnsafeMutableBufferPointer<UInt8>, type:argon2_type) -> Int32 {
		let out = UnsafeMutablePointer<UInt8>.allocate(capacity:32)
		let encoded = UnsafeMutablePointer<Int8>.allocate(capacity:108)
		defer {
			out.deallocate()
			encoded.deallocate()
		}
		guard argon2_hash(threadCount, 1 << memoryCount, parallelismCount, pwd.baseAddress, pwd.count, salt.baseAddress, salt.count, out, 32, encoded, 108, type, version) == ARGON2_OK.rawValue else {
			XCTFail("argon2_hash failed")
			return -1
		}
		return argon2_verify(encoded, pwd.baseAddress, pwd.count, type)
	}

	static func testArgonHashing(password:String, salt:String, hexReference:String, mcReference:String) -> Int32 {
		var password = Array(password.utf8)
		var somesalt = Array(salt.utf8)
		var hexRef = Array(hexReference.utf8)
		var mcRef = Array(mcReference.utf8)
		return password.RAW_access_mutating { (passwordBuffer:UnsafeMutableBufferPointer<UInt8>) in
			return somesalt.RAW_access_mutating { (saltBuffer:UnsafeMutableBufferPointer<UInt8>) in
				return hexRef.RAW_access_mutating { (hexRefBuffer:UnsafeMutableBufferPointer<UInt8>) in
					return mcRef.RAW_access_mutating { (mcRefBuffer:UnsafeMutableBufferPointer<UInt8>) in
						return hashTest(version:ARGON2_VERSION_13.rawValue, threadCount:2, memoryCount:16, parallelismCount:1, pwd:passwordBuffer, salt:saltBuffer, hexRef:hexRefBuffer, mcRef:mcRefBuffer, type:Argon2_i)
					}
				}
			}
		}
	}

	func testArgonHashTests() throws {
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"somesalt", hexReference:"f6c4db4a54e2a370627aff3db6176b94a2a209a62c8e36152711802f7b30c694", mcReference:"$argon2i$m=1048576,t=2,p=1$c29tZXNhbHQ$lpDsVdKNPtMlYvLnPqYrArAYdXZDoq5ueVKEWd6BBuk") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"somesalt", hexReference:"f6c4db4a54e2a370627aff3db6176b94a2a209a62c8e36152711802f7b30c694", mcReference:"$argon2i$m=65536,t=2,p=1$c29tZXNhbHQ$9sTbSlTio3Biev89thdrlKKiCaYsjjYVJxGAL3swxpQ") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"somesalt", hexReference:"f6c4db4a54e2a370627aff3db6176b94a2a209a62c8e36152711802f7b30c694", mcReference:"$argon2i$m=262144,t=2,p=1$c29tZXNhbHQ$Pmiaqj0op3zyvHKlGsUxZnYXURgvHuKS4/Z3p9pMJGc") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"somesalt", hexReference:"f6c4db4a54e2a370627aff3db6176b94a2a209a62c8e36152711802f7b30c694", mcReference:"$argon2i$m=256,t=2,p=1$c29tZXNhbHQ$/U3YPXYsSb3q9XxHvc0MLxur+GP960kN9j7emXX8zwY") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"somesalt", hexReference:"b6c11560a6a9d61eac706b79a2f97d68b4463aa3ad87e00c07e2b01e90c564fb", mcReference:"$argon2i$m=256,t=2,p=2$c29tZXNhbHQ$tsEVYKap1h6scGt5ovl9aLRGOqOth+AMB+KwHpDFZPs") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"somesalt", hexReference:"81630552b8f3b1f48cdb1992c4c678643d490b2b5eb4ff6c4b3438b5621724b2", mcReference:"$argon2i$m=65536,t=1,p=1$c29tZXNhbHQ$gWMFUrjzsfSM2xmSxMZ4ZD1JCytetP9sSzQ4tWIXJLI") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"somesalt", hexReference:"f212f01615e6eb5d74734dc3ef40ade2d51d052468d8c69440a3a1f2c1c2847b", mcReference:"$argon2i$m=65536,t=4,p=1$c29tZXNhbHQ$8hLwFhXm6110c03D70Ct4tUdBSRo2MaUQKOh8sHChHs") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"differentpassword", salt:"somesalt", hexReference:"e9c902074b6754531a3a0be519e5baf404b30ce69b3f01ac3bf21229960109a3", mcReference:"$argon2i$m=65536,t=2,p=1$c29tZXNhbHQ$6ckCB0tnVFMaOgvlGeW69ASzDOabPwGsO/ISKZYBCaM") == ARGON2_OK.rawValue, true)
		XCTAssertEqual(Self.testArgonHashing(password:"password", salt:"diffsalt", hexReference:"79a103b90fe8aef8570cb31fc8b22259778916f8336b7bdac3892569d4f1c497", mcReference:"$argon2i$m=65536,t=2,p=1$ZGlmZnNhbHQ$eaEDuQ/orvhXDLMfyLIiWXeJFvgza3vaw4kladTxxJc") == ARGON2_OK.rawValue, true)
	}

	func testArgon2Verify() throws {
		XCTAssertNotEqual(argon2_verify("$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQwWKIMhR9lyDFvRz9YTZweHKfbftvj+qf+YFY4NeBbtA", "password", strlen("password"), Argon2_i), ARGON2_OK.rawValue)
		XCTAssertNotEqual(argon2_verify("$argon2i$m=65536,t=2,p=1c29tZXNhbHQ$9sTbSlTio3Biev89thdrlKKiCaYsjjYVJxGAL3swxpQ", "password", strlen("password"), Argon2_i), ARGON2_OK.rawValue)
		XCTAssertNotEqual(argon2_verify("$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$8iIuixkI73Js3G1uMbezQXD0b8LG4SXGsOwoQkdAQIM", "password", strlen("password"), Argon2_i), ARGON2_OK.rawValue)
	}
}