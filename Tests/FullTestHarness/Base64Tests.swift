// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import CRAW_base64
@testable import RAW_base64
@testable import RAW

extension rawdog_tests {
	@Suite("RAW_base64", 
		.serialized
	)
	struct Base64Tests {
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
	
		@Test("RAW_base64 :: length tests")
		func testBase64LengthTests() throws {
			// test that padding deltas are zero for sizes that are multiples of 3.
			for i in 0..<64 {
				// verify aligned lengths
				let alignedSize = i * 3
				let alignedReferenceImplEncLen = base64_encoded_length(alignedSize)
				let alignedReferenceImplDecLen = base64_decoded_length(alignedReferenceImplEncLen)
				let alignedEncodingByteLengthPadded = RAW_base64.Encode.padded_length(unencoded_byte_count:alignedSize)
				let alignedEncodingByteLengthUnpadded = RAW_base64.Encode.unpadded_length(unencoded_byte_count:alignedSize)
				let alignedDecodedByteLengthFromUnpadded = try RAW_base64.Decode.length(unpadded_encoding_byte_length:alignedEncodingByteLengthUnpadded)
				let alignedDecodedByteLengthFromPadded = RAW_base64.Decode.length(padded_encoding_byte_length:alignedEncodingByteLengthPadded)
				
				// verify that the padded encoding byte length is the same as the reference implementation.
				#expect(alignedReferenceImplEncLen == alignedEncodingByteLengthPadded)
				// verify that the unpadded encoding byte length is the same as the padded encoding byte length, since we are working with aligned sizes atm.
				#expect(alignedEncodingByteLengthPadded == alignedEncodingByteLengthUnpadded)
				// verify that the computed length for the decoded values are the same as the aligned size (based on the unpadded encoding byte length)
				#expect(alignedDecodedByteLengthFromUnpadded == alignedSize)
				// verify that the computed length for the decoded values are the same as the aligned size (based on the padded encoding byte length)
				#expect(alignedDecodedByteLengthFromPadded == alignedReferenceImplDecLen)

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
					#expect(swift_truth_aligned_encoded == cref_truth_aligned_encoded)
					let (swift_truth_aligned_decoded, cref_truth_aligned_decoded) = try Base64Tests.compareStringDecodes(swift_truth_aligned_encoded)
					#expect(swift_truth_aligned_decoded == cref_truth_aligned_decoded)
				}

				// verify unaligned lengths
				// - unaligned +1
				let misalignByOne = (i * 3) + 1
				let misalignedByOneReferenceImplEncLen = base64_encoded_length(misalignByOne)
				let misalignedByOneReferenceImplDecLen = base64_decoded_length(misalignedByOneReferenceImplEncLen)

				let misalignedByOneEncodingByteLengthPadded = RAW_base64.Encode.padded_length(unencoded_byte_count:misalignByOne)
				// verify that the +1 misaligned padded encoding byte length is the same as the reference implementation.
				#expect(misalignedByOneReferenceImplEncLen == misalignedByOneEncodingByteLengthPadded)
				// verify that the +1 misaligned padded encoding byte length is 4 greater than the aligned encoding byte length.
				#expect(misalignedByOneEncodingByteLengthPadded == alignedEncodingByteLengthPadded + 4)

				let misalignedByOneEncodingByteLengthUnpadded = RAW_base64.Encode.unpadded_length(unencoded_byte_count:misalignByOne)
				// verify that the unpadded encoding length is 2 less than the aligned encoding byte length
				#expect(misalignedByOneEncodingByteLengthPadded == misalignedByOneEncodingByteLengthUnpadded + 2)

				let misalignedByOneDecodedByteLengthFromUnpadded = try RAW_base64.Decode.length(unpadded_encoding_byte_length:misalignedByOneEncodingByteLengthUnpadded)
				// verify that the computed length for the decoded values are the same as the misaligned (by one) size (based on the unpadded encoding byte length for the same misalignment)
				#expect(misalignedByOneDecodedByteLengthFromUnpadded == misalignByOne)

				let misalignedByOneDecodedByteLengthFromPadded = RAW_base64.Decode.length(padded_encoding_byte_length:misalignedByOneEncodingByteLengthPadded)
				// verify that the computed length for the decoded values are the same as the reference implementation (for padded encoding byte length)
				#expect(misalignedByOneDecodedByteLengthFromPadded == misalignedByOneReferenceImplDecLen)

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
					#expect(swift_truth_misalignedByOne_encoded == cref_truth_misalignedByOne_encoded)
					let (swift_truth_misalignedByOne_decoded, cref_truth_misalignedByOne_decoded) = try Base64Tests.compareStringDecodes(swift_truth_misalignedByOne_encoded)
					#expect(swift_truth_misalignedByOne_decoded == cref_truth_misalignedByOne_decoded)
				}

				// - unaligned +2
				let misalignByTwo = (i * 3) + 2
				let misalignedByTwoReferenceImplEncLen = base64_encoded_length(misalignByTwo)
				let misalignedByTwoReferenceImplDecLen = base64_decoded_length(misalignedByTwoReferenceImplEncLen)

				let misalignedByTwoEncodingByteLengthPadded = RAW_base64.Encode.padded_length(unencoded_byte_count:misalignByTwo)
				// verify that the +2 misaligned padded encoding byte length is the same as the reference implementation.
				#expect(misalignedByTwoReferenceImplEncLen == misalignedByTwoEncodingByteLengthPadded)
				// verify that the +2 misaligned padded encoding byte length is the same length as the +1 misaligned padded encoding byte length.
				#expect(misalignedByTwoEncodingByteLengthPadded == misalignedByOneEncodingByteLengthPadded)

				let misalignedByTwoEncodingByteLengthUnpadded = RAW_base64.Encode.unpadded_length(unencoded_byte_count:misalignByTwo)
				// verify that the unpadded encoding length is 1 less than the aligned encoding byte length
				#expect(misalignedByTwoEncodingByteLengthPadded == misalignedByTwoEncodingByteLengthUnpadded + 1)

				let misalignedByTwoDecodedByteLengthFromUnpadded = try RAW_base64.Decode.length(unpadded_encoding_byte_length:misalignedByTwoEncodingByteLengthUnpadded)
				// verify that the computed length for the decoded values are the same as the misaligned (by two) size (based on the unpadded encoding byte length for the same misalignment)
				#expect(misalignedByTwoDecodedByteLengthFromUnpadded == misalignByTwo)

				let misalignedByTwoDecodedByteLengthFromPadded = RAW_base64.Decode.length(padded_encoding_byte_length:misalignedByTwoEncodingByteLengthPadded)
				// verify that the computed length for the decoded values are the same as the reference implementation (for padded encoding byte length)
				#expect(misalignedByTwoDecodedByteLengthFromPadded == misalignedByTwoReferenceImplDecLen)

				for _ in 0..<256 {
					let misalignedByTwoTestData = [UInt8](unsafeUninitializedCapacity:misalignByTwo, initializingWith: { buffer, countup in
						countup = 0
						for _ in 0..<misalignByTwo {
							buffer[countup] = UInt8.random(in:0..<255)
							countup += 1
						}
					})
					let (swift_truth_misalignedByTwo_encoded, cref_truth_misalignedByTwo_encoded) = try Base64Tests.compareStringExports(misalignedByTwoTestData)
					#expect(swift_truth_misalignedByTwo_encoded == cref_truth_misalignedByTwo_encoded)
					let (swift_truth_misalignedByTwo_decoded, cref_truth_misalignedByTwo_decoded) = try Base64Tests.compareStringDecodes(swift_truth_misalignedByTwo_encoded)
					#expect(swift_truth_misalignedByTwo_decoded == cref_truth_misalignedByTwo_decoded)
				}
			}
		}
	
		// at one point in development I wrote a bug and throught there was something special about this pattern. there is nothing special about this pattern, but why not test it anyways?
		@Test("RAW_base64 :: problematic pattern")
		func testProblematicPattern() throws {
			let troubles:[UInt8] = [159, 190, 109, 249, 241, 133, 53, 203, 146, 151, 236, 5, 151, 249, 85, 252, 68, 70, 160, 36, 37, 249, 56, 31, 43, 176, 2, 227, 7, 61, 229, 153, 64, 143, 193, 176, 46, 81, 233, 154, 242, 71, 90, 85, 69, 231, 44, 140, 167, 131, 243, 230, 183, 208, 236, 179, 127, 251, 84, 209, 211, 189, 238, 230]
			let troublesEncoded = RAW_base64.encode(troubles)
			let asString = String(troublesEncoded)
			#expect(asString == "n75t+fGFNcuSl+wFl/lV/ERGoCQl+TgfK7AC4wc95ZlAj8GwLlHpmvJHWlVF5yyMp4Pz5rfQ7LN/+1TR073u5g==")
			let recoded = try RAW_base64.decode(asString)
			#expect(recoded == troubles)
		}
	
		// // testing base64 encoding from bytes.
		@Test("RAW_base64 :: encode from bytes")
		func testBase64EncodingFromBytes() {
			let bytes: [UInt8] = Array("Hello, World!".utf8)
			let base64Encoded = RAW_base64.encode(bytes)
			#expect(String(base64Encoded) == "SGVsbG8sIFdvcmxkIQ==")
	
			let loopTestString = "SGVsbG8sIFdvcmxkIQ"
			assert(loopTestString.count == base64Encoded.unpaddedEncodedByteCount())
			var iter = base64Encoded.makeIterator()
			for val in loopTestString {
				#expect(val == iter.next()?.characterValue())
			}
			#expect(iter.next() == nil)
		}
	
		// testing base64 decoding to bytes.
		@Test("RAW_base64 :: decoding from bytes")
		func testBase64DecodingToBytes() throws {
			let decodedBytes = try RAW_base64.decode("SGVsbG8sIFdvcmxkIQ==")
			let decodedString = String(bytes: decodedBytes, encoding: .utf8)
			#expect(decodedString == "Hello, World!")
		}
	
		// this should not throw - throwing should be considered a severely unexpected error.
		@Test("RAW_base64 :: no content, no throw")
		func testBase64NoContentNoThrow() {
			let startBytes = [UInt8]()
			let base64Encoded = RAW_base64.encode(startBytes)
			#expect(String(base64Encoded) == "")
			let base64Decoded = try RAW_base64.decode(base64Encoded)
			#expect(base64Decoded == startBytes)
		}
	}
}