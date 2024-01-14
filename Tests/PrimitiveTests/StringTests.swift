import XCTest
import RAW

@RAW_convertible_string_type<UTF8>()
struct _UTF8_str:ExpressibleByStringLiteral {}

class StringTests: XCTestCase {
	// Add your test methods here
	func testRAWEncodeAndDecodeUTF8() {
		let myStarterString:_UTF8_str = "Hello, world!"

	}
}
