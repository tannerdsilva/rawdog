import RAW

internal struct Encode {

	/// computes the padding size for the given number of unencoded bytes.
	/// - returns: the corresponding ``Encoded.Padding`` value.
	internal static func compute_padding(unencoded_byte_count byteCount:size_t) -> Encoded.Padding {
		return switch byteCount % 3 {
			case 0: .zero
			case 1: .two
			case 2: .one
			default: fatalError("byteCount % 3 should never be greater than 2")
		}
	}

	/// computes the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func padded_length(unencoded_byte_count bytes:size_t) -> size_t {
		return ((bytes + 2) / 3) * 4
	}

	/// computes the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func unpadded_length(unencoded_byte_count bytes:size_t) -> size_t {
		let remainingBytes = bytes % 3
		// calculate the length contribution of the remaining bytes
		let remainingBlockLength = switch remainingBytes {
			case 0: 0
			default: remainingBytes + 1
		}
		return ((bytes / 3) * 4) + remainingBlockLength
	}

	internal static func chunk_parse_inline(decoded_bytes bytes:UnsafePointer<UInt8>, decoded_byte_count src_len:size_t, encoded_index:size_t) -> Value {
		let baseBlockIndex = ((encoded_index / 4) * 3)

		#if RAWDOG_BASE64_LOG
		logger.critical("parsing chunk inline", metadata:["baseBlockIndex": "\(baseBlockIndex)", "encoded_index": "\(encoded_index)"])
		#endif

		#if DEBUG
		let encodeSize = Encode.unpadded_length(unencoded_byte_count:src_len)
		assert(encoded_index < encodeSize, "the encoded index should be less than the source length. if it's not, we have a bug. \(encoded_index) >= \(encodeSize)")
		assert(baseBlockIndex < src_len, "the base block index should be less than the source length. if it's not, we have a bug. \(baseBlockIndex) >= \(src_len)")
		#endif
		
		let baseBlockLeftover = encoded_index % 4
		let basePtr = bytes + baseBlockIndex
		let remainingDecodedLength = src_len - baseBlockIndex

		#if DEBUG
		assert(remainingDecodedLength > 0, "remaining decoded length should never be negative")
		#endif

		#if RAWDOG_BASE64_LOG
		logger.info("parsing chunk inline", metadata:["baseBlockIndex": "\(baseBlockIndex)", "baseBlockLeftover": "\(baseBlockLeftover)", "remainingDecodedLength": "\(remainingDecodedLength)", "encoding_length": "\(encodeSize)", "encoded_index": "\(encoded_index)"])
		#endif

		// this switch determines which index the return value will be derived from.
		switch baseBlockLeftover {
			// user wants to access index zero of the quartlet
			case 0:
				// the first byte is unconditional
				return Value(indexValue:(basePtr[0] & 0xfc) >> 2)
			case 1:

				// the result of this byte is dependent on the remaining decoded byte length. if there is only one decoding byte remaining, then the result is the first two bits of the first byte. otherwise, the result is the last two bits of the first byte and the first four bits of the second byte.
				switch remainingDecodedLength {
					case ...0: // handle negative or zero lengths here
						fatalError("remaining decoded length should never be negative")
					case 1:
						return Value(indexValue:((basePtr[0] & 0x3) << 4))
					default:
						return Value(indexValue:(((basePtr[0] & 0x3) << 4) | ((basePtr[1] & 0xf0) >> 4)))
				}
			case 2:
				// the result of this byte is dependent on the remaining decoded byte length. if there is only one decoding byte remaining, then the result is the last four bits of the first byte. otherwise, the result is the last four bits of the first byte and the first two bits of the second byte.
				switch remainingDecodedLength {
					case ...1: // any index less than or equal to 1 is invalid
						fatalError("remaining decoded length should never be negative")
					case 2:
						return Value(indexValue:((basePtr[1] & 0xf) << 2))
					default:
						return Value(indexValue:((basePtr[1] & 0xf) << 2) | ((basePtr[2] & 0xc0) >> 6))
				}
			case 3:
				#if DEBUG
				assert(remainingDecodedLength >= 3, "out of bounds access to decoded bytes")
				#endif

				return Value(indexValue:(basePtr[2] & 0x3f))
				
			default:
				fatalError("encoded index % 4 should never be greater than 3")
		}
	}

	// triplets in
	// quadruplets out
	internal static func chunk_parse(_ dest_ptr:inout UnsafeMutablePointer<Value>, _ dest_len:inout size_t, _ src:inout UnsafePointer<UInt8>, _ src_len:inout size_t, _ encoded_tail:inout Encoded.Padding) {
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
}