// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import XCTest
@testable import RAW_hex

class HexTests: XCTestCase {
	func testHexDecode() throws {
		let hexString:Encoded = "0123456789abcdef"
		let expectedData:Encoded = [.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .a, .b, .c, .d, .e, .f]
		let result = [UInt8](decode(Encoded(values:[.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .a, .b, .c, .d, .e, .f])))
		XCTAssertEqual(decode(hexString), [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])
		XCTAssertEqual(String(hexString), "0123456789abcdef")
		XCTAssertEqual(decode(expectedData), result)
	}

	func testHexEncodeAndDecodeWithLargeRandomData() throws {
		for _ in 0..<512 {
			let randomData = Encoded(values:[Value].random(count:size_t.random(in:512..<1024) * 2))
			let decodedData = decode(randomData)
			let encString = String(encode(decodedData))
			XCTAssertEqual(String(randomData), encString)
		}
	}
}