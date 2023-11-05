import XCTest
@testable import RAW_base64

class Base64Tests: XCTestCase {
	// testing base64 encoding from raw value.
	func testBase64EncodingFromRaw() {
		Array("Hello, World!".utf8).asRAW_val { rv in
			let base64Encoded = try! Base64.encode(bytes:rv)
			XCTAssertEqual(base64Encoded, "SGVsbG8sIFdvcmxkIQ==")
		}
	}

	// testing base64 encoding from bytes.
	func testBase64EncodingFromBytes() {
		let bytes: [UInt8] = Array("Hello, World!".utf8)
		let base64Encoded = try! Base64.encode(bytes:bytes)
		XCTAssertEqual(base64Encoded, "SGVsbG8sIFdvcmxkIQ==")
	}

	// testing base64 decoding to bytes.
	func testBase64DecodingToBytes() {
		let decodedBytes = try! Base64.decode("SGVsbG8sIFdvcmxkIQ==")
		let decodedString = String(bytes: decodedBytes, encoding: .utf8)
		XCTAssertEqual(decodedString, "Hello, World!")
	}

	// this should not throw - throwing should be considered a severely unexpected error.
	func testBase64NoContentNoThrow() {
		let startBytes = [UInt8]()
		let base64Encoded = try? Base64.encode(bytes:startBytes)
		XCTAssertEqual(base64Encoded, "")
	}
}