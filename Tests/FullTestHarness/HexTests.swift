// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
@testable import RAW_hex

extension rawdog_tests {
	@Suite("RAW_hex",
		.serialized
	)
	struct HexTests {
		@Test("RAW_hex :: decode")
		func testHexDecode() throws {
			let hexString:Encoded = "0123456789abcdef"
			let expectedData:Encoded = [.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .a, .b, .c, .d, .e, .f]
			let result = [UInt8](decode(Encoded(values:[.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .a, .b, .c, .d, .e, .f])))
			#expect(decode(hexString) == [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])
			#expect(String(hexString) == "0123456789abcdef")
			#expect(decode(expectedData) == result)
		}
		@Test("RAW_hex :: encode")
		func testHexEncodeAndDecodeWithLargeRandomData() throws {
			for _ in 0..<512 {
				let randomData = Encoded(values:[Value].random(count:Int.random(in:512..<1024) * 2))
				let decodedData = decode(randomData)
				let encString = String(encode(decodedData))
				#expect(String(randomData) == encString)
			}
		}

		@Test("RAW_hex :: invalid character throws")
		func testInvalidCharacter() {
			do {
				_ = try decode("zz")
				Issue.record("expected an error for an invalid character")
			} catch let error as RAW_hex.Error {
				if case .invalidHexEncodingCharacter = error {
					// expected
				} else {
					Issue.record("wrong error case: \(error)")
				}
			} catch {
				Issue.record("unexpected error type: \(error)")
			}
		}

		@Test("RAW_hex :: odd encoded length throws")
		func testOddLength() {
			do {
				_ = try decode("abc")
				Issue.record("expected an error for an odd encoded length")
			} catch let error as RAW_hex.Error {
				if case .invalidEncodingSize(3) = error {
					// expected
				} else {
					Issue.record("wrong error case: \(error)")
				}
			} catch {
				Issue.record("unexpected error type: \(error)")
			}
		}

		@Test("RAW_hex :: odd-value Encoded(values:) drops the trailing nibble instead of crashing")
		func testOddValueArrayNoCrash() {
			// the non-throwing `Encoded(values:)` path cannot throw
			// `Error.invalidEncodingSize`; it must not force-unwrap into a crash.
			let odd = Encoded(values: [.a, .b, .c])
			let decoded = decode(odd)
			#expect(decoded == [0xAB])
		}

		@Test("RAW_hex :: empty input and case folding")
		func testEmptyAndCase() throws {
			#expect(try decode("") == [])
			#expect(try decode("AB") == [0xAB])
			#expect(try decode("aB") == [0xAB])
			#expect(try decode("0f") == [0x0F])
		}
	}
}