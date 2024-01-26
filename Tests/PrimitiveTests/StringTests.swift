import XCTest
@testable import RAW

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
fileprivate struct _UTF16_CHAR {}

@RAW_convertible_string_type<_UTF16_CHAR>(UTF16)
fileprivate struct MyUTF16:ExpressibleByStringLiteral {}

class StringTests: XCTestCase {
	// Add your test methods here
	func testRAWEncodeAndDecodeUTF16() {
		var myStarterString:MyUTF16 = "Hello, world!"
		var bcount = 0
		let _ = [UInt8](RAW_encodable:&myStarterString, byte_count_out:&bcount)
		XCTAssertEqual(bcount, 26)
		XCTAssertEqual(String(myStarterString), "Hello, world!")
	}
}
