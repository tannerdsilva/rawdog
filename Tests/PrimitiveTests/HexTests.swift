import XCTest
@testable import RAW_hex

class HexTests: XCTestCase {
	func testHexDecode() throws {
		let hexString:Encoded = "0123456789abcdef"
		let expectedData:Encoded = [.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .a, .b, .c, .d, .e, .f]
		let result = try Decode.process(values:[.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .a, .b, .c, .d, .e, .f], count:16)
		XCTAssertEqual(hexString.decoded(), [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])
		XCTAssertEqual(String(hexString), "0123456789abcdef")
		XCTAssertEqual(expectedData.decoded(), result.0)
	}

	func testHexEncodeAndDecodeWithLargeRandomData() throws {
		for _ in 0..<512 {
			let randomData = try Encoded.from(encoded:[Value].random(length:size_t.random(in:512..<1024) * 2))
			let decodedData = randomData.decoded()
			let encString = String(Encoded.from(decoded:decodedData))
			XCTAssertEqual(String(randomData), encString)
		}
	}
}