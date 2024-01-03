import XCTest
import RAW
import CRAW_base64 // used as reference
@testable import RAW_base64
@testable import RAW

class Base64Tests: XCTestCase {

	func testBase64LengthTests() {
		// test that padding deltas are zero for sizes that are multiples of 3.
		for i in 0..<64 {

			// verify aligned lengths
			let alignedSize = i * 3
			let alignedReferenceImplEncLen = base64_encoded_length(alignedSize)
			let alignedReferenceImplDecLen = base64_decoded_length(alignedReferenceImplEncLen)
			let alignedEncodingByteLengthPadded = RAW_base64.Encode.padded_length(unencoded_byte_count:alignedSize)
			let alignedEncodingByteLengthUnpadded = RAW_base64.Encode.unpadded_length(unencoded_byte_count:alignedSize)
			let alignedDecodedByteLengthFromUnpadded = try! RAW_base64.Decode.length(unpadded_encoding_byte_length:alignedEncodingByteLengthUnpadded)
			let alignedDecodedByteLengthFromPadded = RAW_base64.Decode.length(padded_encoding_byte_length:alignedEncodingByteLengthPadded)
			
			// verify that the padded encoding byte length is the same as the reference implementation.
			XCTAssertEqual(alignedReferenceImplEncLen, alignedEncodingByteLengthPadded)
			// verify that the unpadded encoding byte length is the same as the padded encoding byte length, since we are working with aligned sizes atm.
			XCTAssertEqual(alignedEncodingByteLengthPadded, alignedEncodingByteLengthUnpadded)
			// verify that the computed length for the decoded values are the same as the aligned size (based on the unpadded encoding byte length)
			XCTAssertEqual(alignedDecodedByteLengthFromUnpadded, alignedSize)
			// verify that the computed length for the decoded values are the same as the aligned size (based on the padded encoding byte length)
			XCTAssertEqual(alignedDecodedByteLengthFromPadded, alignedReferenceImplDecLen)

			// verify unaligned lengths
			// - unaligned +1
			let misalignByOne = (i * 3) + 1
			let misalignedByOneReferenceImplEncLen = base64_encoded_length(misalignByOne)
			let misalignedByOneReferenceImplDecLen = base64_decoded_length(misalignedByOneReferenceImplEncLen)

			let misalignedByOneEncodingByteLengthPadded = RAW_base64.Encode.padded_length(unencoded_byte_count:misalignByOne)
			// verify that the +1 misaligned padded encoding byte length is the same as the reference implementation.
			XCTAssertEqual(misalignedByOneReferenceImplEncLen, misalignedByOneEncodingByteLengthPadded)
			// verify that the +1 misaligned padded encoding byte length is 4 greater than the aligned encoding byte length.
			XCTAssertEqual(misalignedByOneEncodingByteLengthPadded, alignedEncodingByteLengthPadded + 4)

			let misalignedByOneEncodingByteLengthUnpadded = RAW_base64.Encode.unpadded_length(unencoded_byte_count:misalignByOne)
			// verify that the unpadded encoding length is 2 less than the aligned encoding byte length
			XCTAssertEqual(misalignedByOneEncodingByteLengthPadded, misalignedByOneEncodingByteLengthUnpadded + 2)

			let misalignedByOneDecodedByteLengthFromUnpadded = try! RAW_base64.Decode.length(unpadded_encoding_byte_length:misalignedByOneEncodingByteLengthUnpadded)
			// verify that the computed length for the decoded values are the same as the misaligned (by one) size (based on the unpadded encoding byte length for the same misalignment)
			XCTAssertEqual(misalignedByOneDecodedByteLengthFromUnpadded, misalignByOne)

			let misalignedByOneDecodedByteLengthFromPadded = RAW_base64.Decode.length(padded_encoding_byte_length:misalignedByOneEncodingByteLengthPadded)
			// verify that the computed length for the decoded values are the same as the reference implementation (for padded encoding byte length)
			XCTAssertEqual(misalignedByOneDecodedByteLengthFromPadded, misalignedByOneReferenceImplDecLen)

			// - unaligned +2
			let misalignByTwo = (i * 3) + 2
			let misalignedByTwoReferenceImplEncLen = base64_encoded_length(misalignByTwo)
			let misalignedByTwoReferenceImplDecLen = base64_decoded_length(misalignedByTwoReferenceImplEncLen)

			let misalignedByTwoEncodingByteLengthPadded = RAW_base64.Encode.padded_length(unencoded_byte_count:misalignByTwo)
			// verify that the +2 misaligned padded encoding byte length is the same as the reference implementation.
			XCTAssertEqual(misalignedByTwoReferenceImplEncLen, misalignedByTwoEncodingByteLengthPadded)
			// verify that the +2 misaligned padded encoding byte length is the same length as the +1 misaligned padded encoding byte length.
			XCTAssertEqual(misalignedByTwoEncodingByteLengthPadded, misalignedByOneEncodingByteLengthPadded)

			let misalignedByTwoEncodingByteLengthUnpadded = RAW_base64.Encode.unpadded_length(unencoded_byte_count:misalignByTwo)
			// verify that the unpadded encoding length is 1 less than the aligned encoding byte length
			XCTAssertEqual(misalignedByTwoEncodingByteLengthPadded, misalignedByTwoEncodingByteLengthUnpadded + 1)

			let misalignedByTwoDecodedByteLengthFromUnpadded = try! RAW_base64.Decode.length(unpadded_encoding_byte_length:misalignedByTwoEncodingByteLengthUnpadded)
			// verify that the computed length for the decoded values are the same as the misaligned (by two) size (based on the unpadded encoding byte length for the same misalignment)
			XCTAssertEqual(misalignedByTwoDecodedByteLengthFromUnpadded, misalignByTwo)

			let misalignedByTwoDecodedByteLengthFromPadded = RAW_base64.Decode.length(padded_encoding_byte_length:misalignedByTwoEncodingByteLengthPadded)
			// verify that the computed length for the decoded values are the same as the reference implementation (for padded encoding byte length)
			XCTAssertEqual(misalignedByTwoDecodedByteLengthFromPadded, misalignedByTwoReferenceImplDecLen)
		}
	}

	// // testing base64 encoding from bytes.
	func testBase64EncodingFromBytes() {
		let bytes: [UInt8] = Array("Hello, World!".utf8)
		let base64Encoded = RAW_base64.encode(bytes:bytes)
		XCTAssertEqual(base64Encoded, "SGVsbG8sIFdvcmxkIQ==")
	}

	// testing base64 decoding to bytes.
	func testBase64DecodingToBytes() {
		let decodedBytes = try! RAW_base64.decode("SGVsbG8sIFdvcmxkIQ==")
		let decodedString = String(bytes: decodedBytes, encoding: .utf8)
		XCTAssertEqual(decodedString, "Hello, World!")
	}

	// this should not throw - throwing should be considered a severely unexpected error.
	func testBase64NoContentNoThrow() {
		let startBytes = [UInt8]()
		let base64Encoded = RAW_base64.encode(bytes:startBytes)
		XCTAssertEqual(base64Encoded, "")
	}
}