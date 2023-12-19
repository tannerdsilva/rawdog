import XCTest
import CRAW_base64
import RAW
@testable import RAW_base64
@testable import RAW

class Base64Tests: XCTestCase {

	// used to compare the swift encoding map to the C implementation.
	@StaticBufferType(64, isUnsigned:false)
	fileprivate struct Base64EncodeMap {}

	// used to compare the swift decoding map to the C implementation.
	@StaticBufferType(256, isUnsigned:false)
	fileprivate struct Base64DecodeMap {}

    func testBase64EncodingMap() throws {
		let cEncodingMap = Base64EncodeMap(RAW_staticbuff_storetype:CRAW_base64.base64_maps_rfc4648.encode_map)
		// test the encoding map.
		for i in 0..<64 {
			let char = RAW_base64.RFC4648.EncodeMap[i]
			let cSource = Value(rawValue:UInt8(cEncodingMap[i]))
			XCTAssertEqual(char, cSource)
		}
	}
	
	func testBase64DecodingMap() throws {

		let cDecodingMap = Base64DecodeMap(RAW_staticbuff_storetype:CRAW_base64.base64_maps_rfc4648.decode_map)
		
		for dm in RAW_base64.RFC4648.decodeMap.enumerated() {
			let cSource = UInt8(bitPattern:cDecodingMap[dm.offset])
			XCTAssertEqual(dm.element, cSource)
		}
	}
}

	// testing base64 encodinInt8g from raw value.
	// func testBase64EncodingFromRaw() {
	// 	Array("Hello, World!".utf8).asRAW_val { rawDat, rawSize in
	// 		let base64Encoded = try! RAW_base64.encode(bytes:val(RAW_data:rawDat, RAW_size:rawSize))
	// 		XCTAssertEqual(base64Encoded, "SGVsbG8sIFdvcmxkIQ==")
	// 	}
	// }

	// // testing base64 encoding from bytes.
	// func testBase64EncodingFromBytes() {
	// 	let bytes: [UInt8] = Array("Hello, World!".utf8)
	// 	let base64Encoded = try! RAW_base64.encode(bytes:bytes)
	// 	XCTAssertEqual(base64Encoded, "SGVsbG8sIFdvcmxkIQ==")
	// }

	// // testing base64 decoding to bytes.
	// func testBase64DecodingToBytes() {
	// 	let decodedBytes = try! RAW_base64.decode("SGVsbG8sIFdvcmxkIQ==")
	// 	let decodedString = String(bytes: decodedBytes, encoding: .utf8)
	// 	XCTAssertEqual(decodedString, "Hello, World!")
	// }

	// // this should not throw - throwing should be considered a severely unexpected error.
	// func testBase64NoContentNoThrow() {
	// 	let startBytes = [UInt8]()
	// 	let base64Encoded = try? RAW_base64.encode(bytes:startBytes)
	// 	XCTAssertEqual(base64Encoded, "")
	// }
// }