import RAW

internal struct Encoding {

	/// computes the padding size for the given number of unencoded bytes.
	/// - returns: the corresponding ``Encoded.Tail`` value.
	internal func computePadding(forUnencodedByteCount byteCount:size_t) -> Encoded.Tail {
		return switch byteCount % 3 {
			case 0: .zero
			case 1: .two
			case 2: .one
			default: fatalError("byteCount % 3 should never be greater than 2")
		}
	}

	/// computes the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func encoded_byte_length_padded(forUnencodedByteCount bytes:size_t) -> size_t {
		return ((bytes + 2) / 3) * 4
	}

	/// computes the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func encoded_byte_length_unpadded(forUnencodedByteCount bytes:size_t) -> size_t {
		let remainingBytes = bytes % 3
		// calculate the length contribution of the remaining bytes
		let remainingBlockLength = switch remainingBytes {
			case 0: 0
			default: remainingBytes + 1
		}
		return ((bytes / 3) * 4) + remainingBlockLength
	}

	// triplets in
	// quadruplets out
	fileprivate static func chunk_parse(_ dest_ptr:inout UnsafeMutablePointer<Value>, _ dest_len:inout size_t, _ src:inout UnsafePointer<UInt8>, _ src_len:inout size_t, _ encoded_tail:inout Encoded.Tail) {
		switch src_len {
			case 1:
				// write the tail
				encoded_tail = .two

				dest_ptr[0] = Value(indexValue:((src[0] & 0xfc) >> 2))
				dest_ptr[1] = Value(indexValue:((src[0] & 0x3) << 4)) 
				
				// step the destination pointers
				dest_ptr += 2
				dest_len += 2
				
				// step the source pointers
				src_len -= 1
				src += 1

			case 2:
				// write the tail
				encoded_tail = .one

				dest_ptr[0] = Value(indexValue:((src[0] & 0xfc) >> 2))
				dest_ptr[1] = Value(indexValue:(((src[0] & 0x3) << 4) | ((src[1] & 0xf0) >> 4)))
				dest_ptr[2] = Value(indexValue:((src[1] & 0xf) << 2)) 
				
				// step the destination pointers
				dest_ptr += 3
				dest_len += 3
				
				// step the source pointers
				src_len -= 2
				src += 2

			case 3...:
				#if DEBUG
				assert(encoded_tail == .zero, "the encoded tail should be zero at this point. if it's not, we have a bug.")
				#endif
				
				dest_ptr[0] = Value(indexValue:((src[0] & 0xfc) >> 2))
				dest_ptr[1] = Value(indexValue:(((src[0] & 0x3) << 4) | ((src[1] & 0xf0) >> 4)))
				dest_ptr[2] = Value(indexValue:(((src[1] & 0xf) << 2) | ((src[2] & 0xc0) >> 6)))
				dest_ptr[3] = Value(indexValue:(src[2] & 0x3f))
				
				// step the destination pointers
				dest_ptr += 4
				dest_len += 4
				
				// step the source pointers
				src_len -= 3
				src += 3

			default:
				fatalError("source length is negative")
		}
	}

	/// - note: this function assumes that the destination buffer is large enough to hold the encoded data. despite taking the destination buffer size as a parameter, this function does not check that the destination buffer is large enough to hold the encoded data.
	internal static func encode(bytes data:UnsafePointer<UInt8>, byte_size:size_t) -> Encoded {
		// mutable copy of the size, this will be counted down as we process the data
		var source_byte_countdown = byte_size
		// compute the unpadded length of the encoded data
		let encodedLengthWithoutPadding = Encoding.encoded_byte_length_unpadded(forUnencodedByteCount:source_byte_countdown)

		#if DEBUG
		// when in debug mode, validate that the also store the expected length with padding. this will be audited later.
		let withPadding = Encoding.encoded_byte_length_padded(forUnencodedByteCount:source_byte_countdown)
		#endif

		var destPadding:Encoded.Tail = .zero

		// initialize the [Value] buffer with the encoded length without padding.
		let byteValues = [Value](unsafeUninitializedCapacity:encodedLengthWithoutPadding, initializingWith: { writeBuffer, writeSize in
			
			var srcPtr = data
			var writeseeker = writeBuffer.baseAddress!
			
			while source_byte_countdown > 0 {
				
				#if DEBUG
				// extra sanity checking when in debug mode
				let deltaAudit = writeseeker
				let expectedStepSize = switch source_byte_countdown {
					case 1: 2
					case 2: 3
					case 3...: 4
					default: fatalError("source length exceeds 3 bytes")
				}
				#endif

				Encoding.chunk_parse(&writeseeker, &writeSize, &srcPtr, &source_byte_countdown, &destPadding)
				
				#if DEBUG
				assert(writeseeker - deltaAudit == expectedStepSize, "the write buffer should have advanced by \(expectedStepSize) bytes but was stepped by \(writeseeker - deltaAudit)")
				#endif
			}
			#if DEBUG
			assert(writeSize == encodedLengthWithoutPadding, "the write size should be equal to the encoded length without padding. if it's not, we have a bug. \((writeSize - encodedLengthWithoutPadding))")
			#endif
		})

		#if DEBUG
		assert(encodedLengthWithoutPadding == withPadding - destPadding.asSize(), "the encoded length without padding should be equal to the encoded length with padding minus the padding size")
		#endif

		return Encoded(bytes:byteValues, tail:destPadding)
	}
}