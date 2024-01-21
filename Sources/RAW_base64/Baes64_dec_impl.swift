import RAW

internal struct Decode {

	/// returns the number of bytes that are required to stored the specified encoded data in decoded form.
	internal static func length(unpadded_encoding_byte_length base64Length:size_t) throws -> size_t {
		let remainingBytes = switch base64Length % 4 {
			case 3: 2
			case 2: 1
			case 1: throw Error.invalidEncodingLength(base64Length)
			default: 0
		}
		let fullBlocks = (base64Length) / 4
		return (fullBlocks * 3) + remainingBytes
	}

	/// returns the number of bytes that are required to store the specified encoded data in decoded form.
	internal static func length(padded_encoding_byte_length base64LengthPadded: size_t) -> size_t {
		return ((base64LengthPadded+3)/4*3)
	}

	internal static func chunk_parse_bytes(dest_head:inout UnsafeMutablePointer<UInt8>, dest_length:inout size_t, src_head:inout UnsafePointer<UInt8>, src_length:inout size_t, tail_audit:inout Encoded.Padding) throws {
		switch src_length {
			case 4...:
				#if RAWDOG_BASE64_LOG
				logger.info("parsing quartlet ( \(src_head[0]), \(src_head[1]), \(src_head[2]), \(src_head[3]) )")
				#endif

				// store the data
				let v_i3 = try Value(validate:src_head[3]).indexValue()
				let v_i2 = try Value(validate:src_head[2]).indexValue()
				let v_i1 = try Value(validate:src_head[1]).indexValue()
				let v_i0 = try Value(validate:src_head[0]).indexValue()

				// apply the translation
				dest_head[2] = ((v_i2 & 0x3) << 6) | v_i3
				dest_head[1] = ((v_i1 & 0xf) << 4) | (v_i2 >> 2)
				dest_head[0] = (v_i0 << 2) | (v_i1 >> 4)
				
				// step the destination variables
				dest_head += 3
				dest_length += 3
				
				// step the source variables 
				src_head += 4
				src_length -= 4

				#if DEBUG
				assert(tail_audit == .zero, "the padding audit should be zero at this point. if it's not, we have a bug somewhere in or around this func.")
				#endif
				return

			case 3:
				#if RAWDOG_BASE64_LOG
				logger.info("parsing triplet ( \(src_head[0]), \(src_head[1]), \(src_head[2]) )")
				#endif

				// store the data
				let v_i2 = try Value(validate:src_head[2]).indexValue()
				let v_i1 = try Value(validate:src_head[1]).indexValue()
				let v_i0 = try Value(validate:src_head[0]).indexValue()
				
				// apply the translation
				dest_head[1] = ((v_i1 & 0xf) << 4) | (v_i2 >> 2)
				dest_head[0] = (v_i0 << 2) | (v_i1 >> 4)
				
				// step the destination variables
				dest_head += 2
				dest_length += 2
				
				// step the source variables
				src_head += 3
				src_length -= 3
				
				// write the padding audit value
				tail_audit = .one
				return

			case 2:
				#if RAWDOG_BASE64_LOG
				logger.info("parsing pair ( \(src_head[0]), \(src_head[1]) )")
				#endif

				// store the data
				let v_i1 = try Value(validate:src_head[1]).indexValue()
				let v_i0 = try Value(validate:src_head[0]).indexValue()

				// apply the translation
				dest_head[0] = (v_i0 << 2) | (v_i1 >> 4)
				
				// step the destination variables
				dest_head += 1
				dest_length += 1
				
				// step the source variables
				src_head += 2
				src_length -= 2

				// write the padding audit value
				tail_audit = .two
				return
			
			default:
				fatalError("source length < 2")
		}
	}

	/// decode a chunk of data. this function will usually stride the source pointer by 4 bytes and the destination pointer by 3 bytes, but will also handle partial encodings
	internal static func chunk_parse_values(dest_head:inout UnsafeMutablePointer<UInt8>, dest_length:inout size_t, src_head:inout UnsafePointer<Value>, src_length:inout size_t) {
		switch src_length {
			case 4...:
				// store the data that is referenced mutliple times
				let v_i2 = src_head[2].indexValue()
				let v_i1 = src_head[1].indexValue()
				
				// apply the translation
				dest_head[2] = ((v_i2 & 0x3) << 6) | src_head[3].indexValue()
				dest_head[1] = ((v_i1 & 0xf) << 4) | (v_i2 >> 2)
				dest_head[0] = (src_head[0].indexValue() << 2) | (v_i1 >> 4)
				
				// step the destination variables
				dest_head += 3
				dest_length += 3
				
				// step the source variables 
				src_head += 4
				src_length -= 4
				return

			case 3:
				// store the data that is referenced mutliple times
				let v_i1 = src_head[1].indexValue()
				
				// apply the translation
				dest_head[1] = ((v_i1 & 0xf) << 4) | (src_head[2].indexValue() >> 2)
				dest_head[0] = (src_head[0].indexValue() << 2) | (v_i1 >> 4)
				
				// step the destination variables
				dest_head += 2
				dest_length += 2
				
				// step the source variables
				src_head += 3
				src_length -= 3
				return

			case 2:
				// apply the translation
				dest_head[0] = (src_head[0].indexValue() << 2) | (src_head[1].indexValue() >> 4)
				
				// step the destination variables
				dest_head += 1
				dest_length += 1
				
				// step the source variables
				src_head += 2
				src_length -= 2
				return

			default:
				fatalError("source length < 2")
		}
	}

	/// decode a series of unpadded base64 values into a series of bytes.
	/// - parameter values: the base64 values to decode
	/// - parameter value_count: the number of values to decode
	/// - parameter padding: the padding that was used to encode the data.
	/// - returns: the decoded data.
	/// - throws: throws an error if the length is not a valid length for the given 
	internal static func process(values:UnsafePointer<Value>, value_count:size_t) throws -> ([UInt8], size_t) {
		let decodingSize = try Self.length(unpadded_encoding_byte_length:value_count)
		let decodedBytes = [UInt8](unsafeUninitializedCapacity:decodingSize, initializingWith: { writeBuffer, write_countup in
			write_countup = 0
			var src_countdown = value_count
			var readSeeker = values
			var writeSeeker = writeBuffer.baseAddress!

			// process the data chunks
			while src_countdown > 0 {
				chunk_parse_values(dest_head:&writeSeeker, dest_length:&write_countup, src_head:&readSeeker, src_length:&src_countdown)
			}

			#if DEBUG
			assert(src_countdown == 0, "the source length (countdown) should be zero at this point. if it's not, we have a bug. the countdown value is \(src_countdown)")
			assert(write_countup == decodingSize, "the size of the decoded data should be equal to the expected size. if it's not, we have a bug. \((write_countup - decodingSize))")
			#endif
		})
		return (decodedBytes, decodingSize)
	}

	internal static func process(bytes:UnsafePointer<UInt8>, byte_count:size_t, padding_audit expected_padding:Encoded.Padding) throws -> ([UInt8], size_t) {
		let decodingSize = try Self.length(unpadded_encoding_byte_length:byte_count)
		return (try [UInt8](unsafeUninitializedCapacity:decodingSize, initializingWith: { writeBuffer, write_countup in
			write_countup = 0
			var src_countdown = byte_count
			var readSeeker = bytes
			var writeSeeker = writeBuffer.baseAddress!
			var padding_audit:Encoded.Padding = .zero

			// process the data chunks
			while src_countdown > 0 {
				try chunk_parse_bytes(dest_head:&writeSeeker, dest_length:&write_countup, src_head:&readSeeker, src_length:&src_countdown, tail_audit:&padding_audit)
			}

			#if DEBUG
			assert(src_countdown == 0, "the source length (countdown) should be zero at this point. if it's not, we have a bug. the countdown value is \(src_countdown)")
			assert(write_countup == decodingSize, "the size of the decoded data should be equal to the expected size. if it's not, we have a bug. \((write_countup - decodingSize))")
			#endif

			// verify the padding
			guard padding_audit == expected_padding else {
				throw Error.invalidPaddingLength
			}
		}), decodingSize)
	}
}

