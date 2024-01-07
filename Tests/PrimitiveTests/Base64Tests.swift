import XCTest
import CRAW_base64
@testable import RAW_base64
@testable import RAW

class Base64Tests: XCTestCase {

	/// compares the swift and cref implementations of base64 encoding/decoding.
	static func compareStringExports(_ truth_aligned_data:[UInt8]) throws -> (String, String) {
		let bytes = RAW_base64.encode(truth_aligned_data)
		let swift_truth_aligned_encoded = String(bytes)
		let encLen = base64_encoded_length(truth_aligned_data.count)
		let cref_truth_aligned_encoded = String(cString:[CChar](unsafeUninitializedCapacity:encLen, initializingWith: { buffer, countup in
			countup = 0
			countup = base64_encode(buffer.baseAddress, encLen, truth_aligned_data, truth_aligned_data.count)
		}) + [0])
		return (swift_truth_aligned_encoded, cref_truth_aligned_encoded)
	}

	static func compareStringDecodes(_ stringToDecode:String) throws -> ([UInt8], [UInt8]) {
		let swift_truth_aligned_decoded = try RAW_base64.decode(stringToDecode)
		let cref_truth_aligned_decoded = [UInt8](unsafeUninitializedCapacity:base64_decoded_length(stringToDecode.count), initializingWith: { buffer, countup in
			countup = 0
			countup = base64_decode(buffer.baseAddress, buffer.count, stringToDecode, stringToDecode.count)
		})
		return (swift_truth_aligned_decoded, cref_truth_aligned_decoded)
	
	}

	func testBase64LengthTests() {
		// test that padding deltas are zero for sizes that are multiples of 3.
		for i in 0..<64 {
			do {
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

				for _ in 0..<256 {
					// generate data against this aligned size. 
					let alignedTestData = [UInt8](unsafeUninitializedCapacity:alignedSize, initializingWith: { buffer, countup in
						countup = 0
						for _ in 0..<alignedSize {
							buffer[countup] = UInt8.random(in:0..<255)
							countup += 1
						}
					})
					let (swift_truth_aligned_encoded, cref_truth_aligned_encoded) = try Base64Tests.compareStringExports(alignedTestData)
					XCTAssertEqual(swift_truth_aligned_encoded, cref_truth_aligned_encoded)
					let (swift_truth_aligned_decoded, cref_truth_aligned_decoded) = try Base64Tests.compareStringDecodes(swift_truth_aligned_encoded)
					XCTAssertEqual(swift_truth_aligned_decoded, cref_truth_aligned_decoded)
				}

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

				// generate data against this aligned size. 
				for _ in 0..<256 {
					let misalignedByOneTestData = [UInt8](unsafeUninitializedCapacity:misalignByOne, initializingWith: { buffer, countup in
						countup = 0
						for _ in 0..<misalignByOne {
							buffer[countup] = UInt8.random(in:0..<255)
							countup += 1
						}
					})
					let (swift_truth_misalignedByOne_encoded, cref_truth_misalignedByOne_encoded) = try Base64Tests.compareStringExports(misalignedByOneTestData)
					XCTAssertEqual(swift_truth_misalignedByOne_encoded, cref_truth_misalignedByOne_encoded, "misalignedByOneTestData: \(misalignedByOneTestData)")
					let (swift_truth_misalignedByOne_decoded, cref_truth_misalignedByOne_decoded) = try Base64Tests.compareStringDecodes(swift_truth_misalignedByOne_encoded)
					XCTAssertEqual(swift_truth_misalignedByOne_decoded, cref_truth_misalignedByOne_decoded, "misalignedByOneTestData: \(misalignedByOneTestData)")
				}

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

				for _ in 0..<256 {
					let misalignedByTwoTestData = [UInt8](unsafeUninitializedCapacity:misalignByTwo, initializingWith: { buffer, countup in
						countup = 0
						for _ in 0..<misalignByTwo {
							buffer[countup] = UInt8.random(in:0..<255)
							countup += 1
						}
					})
					let (swift_truth_misalignedByTwo_encoded, cref_truth_misalignedByTwo_encoded) = try Base64Tests.compareStringExports(misalignedByTwoTestData)
					XCTAssertEqual(swift_truth_misalignedByTwo_encoded, cref_truth_misalignedByTwo_encoded)
					let (swift_truth_misalignedByTwo_decoded, cref_truth_misalignedByTwo_decoded) = try Base64Tests.compareStringDecodes(swift_truth_misalignedByTwo_encoded)
					XCTAssertEqual(swift_truth_misalignedByTwo_decoded, cref_truth_misalignedByTwo_decoded)
				}
			} catch {
				XCTFail("unexpected error: \(error)")
			}
		}
	}

	// at one point in development I wrote a bug and throught there was something special about this pattern. there is nothing special about this pattern, in 
	func testProblematicPattern() {
		let troubles:[UInt8] = [159, 190, 109, 249, 241, 133, 53, 203, 146, 151, 236, 5, 151, 249, 85, 252, 68, 70, 160, 36, 37, 249, 56, 31, 43, 176, 2, 227, 7, 61, 229, 153, 64, 143, 193, 176, 46, 81, 233, 154, 242, 71, 90, 85, 69, 231, 44, 140, 167, 131, 243, 230, 183, 208, 236, 179, 127, 251, 84, 209, 211, 189, 238, 230]
		let troublesEncoded = RAW_base64.encode(troubles)
		let asString = String(troublesEncoded)
		XCTAssertEqual(asString, "n75t+fGFNcuSl+wFl/lV/ERGoCQl+TgfK7AC4wc95ZlAj8GwLlHpmvJHWlVF5yyMp4Pz5rfQ7LN/+1TR073u5g==")
		let recoded = try! RAW_base64.decode(asString)
		XCTAssertEqual(recoded, troubles)
	}

	// // testing base64 encoding from bytes.
	func testBase64EncodingFromBytes() {
		let bytes: [UInt8] = Array("Hello, World!".utf8)
		let base64Encoded = RAW_base64.encode(bytes)
		XCTAssertEqual(base64Encoded, "SGVsbG8sIFdvcmxkIQ==")

		let loopTestString = "SGVsbG8sIFdvcmxkIQ"
		assert(loopTestString.count == base64Encoded.count)
		for (i, val) in loopTestString.enumerated() {
			XCTAssertEqual(val, base64Encoded[i].characterValue())
		}
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
		let base64Encoded = RAW_base64.encode(startBytes)
		XCTAssertEqual(base64Encoded, "")
	}
}