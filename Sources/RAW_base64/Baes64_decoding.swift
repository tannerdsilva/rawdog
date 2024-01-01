import RAW

internal struct Decoding {

	// returns the number of bytes that are required to stored the specified encoded data in decoded form.
	internal static func decoded_byte_length(unpadded_encoding_byte_length base64Length:size_t) throws -> size_t {
		let fullBlocks = base64Length / 4
		let remainingBytes = switch base64Length % 4 {
			case 3: 2
			case 2: 1
			case 1: throw Error.invalidEncodingLength(base64Length)
			default: 0
		}
		return (fullBlocks * 3) + remainingBytes
	}

	// decode a chunk of data
	internal static func decode_chunk(dest_head:inout UnsafeMutablePointer<UInt8>, dest_length:inout size_t, src_head:inout UnsafePointer<Value>, src_length:inout size_t, tail_audit:inout Encoded.Tail) {
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

				#if DEBUG
				assert(tail_audit == .zero, "the padding audit should be zero at this point. if it's not, we have a bug.")
				#endif
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
				
				// write the padding audit value
				tail_audit = .one
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
				
				// write the padding audit value
				tail_audit = .two
				return

			default:
				fatalError("source length < 2")
		}
	}

	internal static func base64_decode(values:UnsafePointer<Value>, value_count:size_t, padding:Encoded.Tail) throws -> [UInt8] {
		let decodingSize = try decoded_byte_length(unpadded_encoding_byte_length:value_count)
		return [UInt8](unsafeUninitializedCapacity:decodingSize, initializingWith: { writeBuffer, write_countup in
			write_countup = 0
			var src_countdown = value_count
			var readSeeker = values
			var writeSeeker = writeBuffer.baseAddress!
			var paddingAudit:Encoded.Tail = .zero

			// process the data chunks
			while src_countdown > 0 {
				decode_chunk(dest_head:&writeSeeker, dest_length:&write_countup, src_head:&readSeeker, src_length:&src_countdown, tail_audit:&paddingAudit)
			}

			#if DEBUG
			assert(src_countdown == 0, "the source length (countdown) should be zero at this point. if it's not, we have a bug. the countdown value is \(src_countdown)")
			assert(write_countup == decodingSize, "the size of the decoded data should be equal to the expected size. if it's not, we have a bug. \((write_countup - decodingSize))")
			#endif
		})
	}
}

