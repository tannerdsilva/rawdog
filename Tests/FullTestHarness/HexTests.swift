// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
@testable import RAW_hex
import struct RAW.size_t

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
				let randomData = Encoded(values:[Value].random(count:size_t.random(in:512..<1024) * 2))
				let decodedData = decode(randomData)
				let encString = String(encode(decodedData))
				#expect(String(randomData) == encString)
			}
		}
	}
}