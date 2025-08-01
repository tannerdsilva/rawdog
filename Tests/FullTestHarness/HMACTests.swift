import Testing
@testable import RAW_md5
@testable import RAW_sha1
@testable import RAW_sha256
@testable import RAW_sha512
@testable import RAW_hmac
import RAW_hex
import RAW

extension rawdog_tests {
	/// test vectors taken from https://datatracker.ietf.org/doc/html/rfc4231 and https://datatracker.ietf.org/doc/html/rfc2202
	@Suite("RAW_hmac :: sha1 & sha256 & sha512",
		.serialized
	)
	struct RAWHMACTests {
		@Test("RAW_hmac :: test vector 1 (md5, sha1, sha256 & sha512)")
		func testVector1() throws {
			let key = [UInt8](repeating: 0x0B, count: 20)
			let messages:[[UInt8]] = [[UInt8]("Hi There".utf8)]
			#expect(key.dropLast(4).count == 16)
			var hmac5 = try RAW_hmac.HMAC<RAW_md5.Hasher<RAW_md5.Hash>>(key:key.dropLast(4))
			var hmac1 = try RAW_hmac.HMAC<RAW_sha1.Hasher<RAW_sha1.Hash>>(key:key)
			var hmac256 = try RAW_hmac.HMAC<RAW_sha256.Hasher<RAW_sha256.Hash>>(key:key)
			var hmac512 = try RAW_hmac.HMAC<RAW_sha512.Hasher<RAW_sha512.Hash>>(key:key)
			for msg in messages {
				try hmac5.update(message:msg)
				try hmac1.update(message:msg)
				try hmac256.update(message:msg)
				try hmac512.update(message:msg)
			}
			let expected5 = try RAW_hex.decode("9294727a3638bb1c13f48ef8158bfc9d")
			let expected1 = try RAW_hex.decode("b617318655057264e28bc0b6fb378c8ef146be00")
			let expected256 = try RAW_hex.decode("b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7")
			let expected512 = try RAW_hex.decode("87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854")
			try hmac5.finish().RAW_access {
				#expect([UInt8]($0) == expected5)
			}
			try hmac1.finish().RAW_access {
				#expect([UInt8]($0) == expected1)
			}
			try hmac256.finish().RAW_access {
				#expect([UInt8]($0) == expected256)
			}
			try hmac512.finish().RAW_access {
				#expect([UInt8]($0) == expected512)
			}
		}

		@Test("RAW_hmac :: test vector 2 (md5, sha1, sha256 & sha512)")
		func testVector2() throws {
			let key = [UInt8]("Jefe".utf8)
			let messages:[[UInt8]] = [[UInt8]("what do ya want ".utf8), [UInt8]("for nothing?".utf8)]
			var hmac5 = try RAW_hmac.HMAC<RAW_md5.Hasher<RAW_md5.Hash>>(key:key)
			var hmac1 = try RAW_hmac.HMAC<RAW_sha1.Hasher<RAW_sha1.Hash>>(key:key)
			var hmac256 = try RAW_hmac.HMAC<RAW_sha256.Hasher<RAW_sha256.Hash>>(key:key)
			var hmac512 = try RAW_hmac.HMAC<RAW_sha512.Hasher<RAW_sha512.Hash>>(key:key)
			for msg in messages {
				try hmac5.update(message:msg)
				try hmac1.update(message:msg)
				try hmac256.update(message:msg)
				try hmac512.update(message:msg)
			}
			let expected5 = try RAW_hex.decode("750c783e6ab0b503eaa86e310a5db738")
			let expected1 = try RAW_hex.decode("effcdf6ae5eb2fa2d27416d5f184df9c259a7c79")
			let expected256 = try RAW_hex.decode("5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843")
			let expected512 = try RAW_hex.decode("164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea2505549758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737")

			try hmac5.finish().RAW_access {
				#expect([UInt8]($0) == expected5)
			}
			try hmac1.finish().RAW_access {
				#expect([UInt8]($0) == expected1)
			}
			try hmac256.finish().RAW_access {
				#expect([UInt8]($0) == expected256)
			}
			try hmac512.finish().RAW_access {
				#expect([UInt8]($0) == expected512)
			}
		}

		@Test("RAW_hmac :: test vector 3 (md5 & sha1 & sha256 & sha512)")
		func testVector3() throws {
			let key = [UInt8](repeating: 0xAA, count: 20)
			let messages:[[UInt8]] = [[UInt8](repeating: 0xDD, count: 50)]
			#expect(key.dropLast(4).count == 16)
			var hmac5 = try RAW_hmac.HMAC<RAW_md5.Hasher<RAW_md5.Hash>>(key:key.dropLast(4))
			var hmac1 = try RAW_hmac.HMAC<RAW_sha1.Hasher<RAW_sha1.Hash>>(key:key)
			var hmac256 = try RAW_hmac.HMAC<RAW_sha256.Hasher<RAW_sha256.Hash>>(key:key)
			var hmac512 = try RAW_hmac.HMAC<RAW_sha512.Hasher<RAW_sha512.Hash>>(key:key)
			for msg in messages {
				try hmac5.update(message:msg)
				try hmac1.update(message:msg)
				try hmac256.update(message:msg)
				try hmac512.update(message:msg)
			}
			let expected5 = try RAW_hex.decode("56be34521d144c88dbb8c733f0e8b3f6")
			let expected1 = try RAW_hex.decode("125d7342b9ac11cd91a39af48aa17b4f63f175d3")
			let expected256 = try RAW_hex.decode("773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe")
			let expected512 = try RAW_hex.decode("fa73b0089d56a284efb0f0756c890be9b1b5dbdd8ee81a3655f83e33b2279d39bf3e848279a722c806b485a47e67c807b946a337bee8942674278859e13292fb")

			try hmac5.finish().RAW_access {
				#expect([UInt8]($0) == expected5)
			}
			try hmac1.finish().RAW_access {
				#expect([UInt8]($0) == expected1)
			}
			try hmac256.finish().RAW_access {
				#expect([UInt8]($0) == expected256)
			}
			try hmac512.finish().RAW_access {
				#expect([UInt8]($0) == expected512)
			}
		}

		@Test("RAW_hmac :: test vector 4 (md5 & sha1 & sha256 & sha512)")
		func testVector4() throws {
			let key = try RAW_hex.decode("0102030405060708090a0b0c0d0e0f10111213141516171819")
			let messages:[[UInt8]] = [[UInt8](repeating:0xCD, count: 50)]
			var hmac5 = try RAW_hmac.HMAC<RAW_md5.Hasher<RAW_md5.Hash>>(key:key)
			var hmac1 = try RAW_hmac.HMAC<RAW_sha1.Hasher<RAW_sha1.Hash>>(key:key)
			var hmac256 = try RAW_hmac.HMAC<RAW_sha256.Hasher<RAW_sha256.Hash>>(key:key)
			var hmac512 = try RAW_hmac.HMAC<RAW_sha512.Hasher<RAW_sha512.Hash>>(key:key)
			for msg in messages {
				try hmac5.update(message:msg)
				try hmac1.update(message:msg)
				try hmac256.update(message:msg)
				try hmac512.update(message:msg)
			}
			let expected5 = try RAW_hex.decode("697eaf0aca3a3aea3a75164746ffaa79")
			let expected1 = try RAW_hex.decode("4c9007f4026250c6bc8414f9bf50c86c2d7235da")
			let expected256 = try RAW_hex.decode("82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b")
			let expected512 = try RAW_hex.decode("b0ba465637458c6990e5a8c5f61d4af7e576d97ff94b872de76f8050361ee3dba91ca5c11aa25eb4d679275cc5788063a5f19741120c4f2de2adebeb10a298dd")
			try hmac5.finish().RAW_access {
				#expect([UInt8]($0) == expected5)
			}
			try hmac1.finish().RAW_access {
				#expect([UInt8]($0) == expected1)
			}
			try hmac256.finish().RAW_access {
				#expect([UInt8]($0) == expected256)
			}
			try hmac512.finish().RAW_access {
				#expect([UInt8]($0) == expected512)
			}
		}

		@Test("RAW_hmac :: test vector 5 (md5 & sha1 & sha256 & sha512)")
		func testVector5() throws {
			let key = [UInt8](repeating: 0x0C, count: 20)
			let messages:[[UInt8]] = [[UInt8]("Test With Truncation".utf8)]
			#expect(key.dropLast(4).count == 16)
			var hmac5 = try RAW_hmac.HMAC<RAW_md5.Hasher<RAW_md5.Hash>>(key:key.dropLast(4))
			var hmac1 = try RAW_hmac.HMAC<RAW_sha1.Hasher<RAW_sha1.Hash>>(key:key)
			var hmac256 = try RAW_hmac.HMAC<RAW_sha256.Hasher<RAW_sha256.Hash>>(key:key)
			var hmac512 = try RAW_hmac.HMAC<RAW_sha512.Hasher<RAW_sha512.Hash>>(key:key)
			for msg in messages {
				try hmac5.update(message:msg)
				try hmac1.update(message:msg)
				try hmac256.update(message:msg)
				try hmac512.update(message:msg)
			}
			let expected5 = try RAW_hex.decode("56461ef2342edc00f9bab995690efd4c")
			let expected1 = try RAW_hex.decode("4c1a03424b55e07fe7f27be1d58bb9324a9a5a04")
			let expected256 = try RAW_hex.decode("a3b6167473100ee06e0c796c2955552b")
			let expected512 = try RAW_hex.decode("415fad6271580a531d4179bc891d87a6")
			try hmac5.finish().RAW_access {
				#expect([UInt8]($0) == expected5)
			}
			try hmac1.finish().RAW_access {
				#expect([UInt8]($0) == expected1)
			}
			try hmac256.finish().RAW_access {
				#expect([UInt8]($0[0..<16]) == expected256)
			}
			try hmac512.finish().RAW_access {
				#expect([UInt8]($0[0..<16]) == expected512)
			}
		}

		@Test("RAW_hmac :: test vector 6 (md5 & sha1 & sha256 & sha512)")
		func testVector6() throws {
			let key = try RAW_hex.decode("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
			let messages:[[UInt8]] = [[UInt8]("Test Using Larger Than Block-Size Key - Hash Key First".utf8)]
			var hmac5 = try RAW_hmac.HMAC<RAW_md5.Hasher<RAW_md5.Hash>>(key:Array(key[0..<80]))
			var hmac1 = try RAW_hmac.HMAC<RAW_sha1.Hasher<RAW_sha1.Hash>>(key:Array(key[0..<80]))
			var hmac256 = try RAW_hmac.HMAC<RAW_sha256.Hasher<RAW_sha256.Hash>>(key:key)
			var hmac512 = try RAW_hmac.HMAC<RAW_sha512.Hasher<RAW_sha512.Hash>>(key:key)
			for msg in messages {
				try hmac5.update(message:msg)
				try hmac1.update(message:msg)
				try hmac256.update(message:msg)
				try hmac512.update(message:msg)
			}
			let expected5 = try RAW_hex.decode("6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd")
			let expected1 = try RAW_hex.decode("aa4ae5e15272d00e95705637ce8a3b55ed402112")
			let expected256 = try RAW_hex.decode("60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54")
			let expected512 = try RAW_hex.decode("80b24263c7c1a3ebb71493c1dd7be8b49b46d1f41b4aeec1121b013783f8f3526b56d037e05f2598bd0fd2215d6a1e5295e64f73f63f0aec8b915a985d786598")
			try hmac5.finish().RAW_access {
				#expect([UInt8]($0) == expected5)
			}
			try hmac1.finish().RAW_access {
				#expect([UInt8]($0) == expected1)
			}
			try hmac256.finish().RAW_access {
				#expect([UInt8]($0) == expected256)
			}
			try hmac512.finish().RAW_access {
				#expect([UInt8]($0) == expected512)
			}
		}

		@Test("RAW_hmac :: test vector 7 (md5 & sha1 & sha256 & sha512)")
		func testVector7() throws {
			let key = try RAW_hex.decode("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
			let message256512 = try RAW_hex.decode("5468697320697320612074657374207573696e672061206c6172676572207468616e20626c6f636b2d73697a65206b657920616e642061206c6172676572207468616e20626c6f636b2d73697a6520646174612e20546865206b6579206e6565647320746f20626520686173686564206265666f7265206265696e6720757365642062792074686520484d414320616c676f726974686d2e")
			let message51:[UInt8] = [UInt8]("Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data".utf8)
			var hmac5 = try RAW_hmac.HMAC<RAW_md5.Hasher<RAW_md5.Hash>>(key:Array(key[0..<80]))
			var hmac1 = try RAW_hmac.HMAC<RAW_sha1.Hasher<RAW_sha1.Hash>>(key:Array(key[0..<80]))
			var hmac256 = try RAW_hmac.HMAC<RAW_sha256.Hasher<RAW_sha256.Hash>>(key:key)
			var hmac512 = try RAW_hmac.HMAC<RAW_sha512.Hasher<RAW_sha512.Hash>>(key:key)
			try hmac5.update(message:message51)
			try hmac1.update(message:message51)
			try hmac256.update(message:message256512)
			try hmac512.update(message:message256512)
			let expected5 = try RAW_hex.decode("6f630fad67cda0ee1fb1f562db3aa53e")
			let expected1 = try RAW_hex.decode("e8e99d0f45237d786d6bbaa7965c7808bbff1a91")
			let expected256 = try RAW_hex.decode("9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2")
			let expected512 = try RAW_hex.decode("e37b6a775dc87dbaa4dfa9f96e5e3ffddebd71f8867289865df5a32d20cdc944b6022cac3c4982b10d5eeb55c3e4de15134676fb6de0446065c97440fa8c6a58")
			try hmac5.finish().RAW_access {
				#expect([UInt8]($0) == expected5)
			}
			try hmac1.finish().RAW_access {
				#expect([UInt8]($0) == expected1)
			}
			try hmac256.finish().RAW_access {
				#expect([UInt8]($0) == expected256)
			}
			try hmac512.finish().RAW_access {
				#expect([UInt8]($0) == expected512)
			}
		}
	}
}