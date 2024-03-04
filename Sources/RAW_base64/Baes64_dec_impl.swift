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
		return (fullBlocks*3) + remainingBytes
	}

	/// returns the number of bytes that are required to store the specified encoded data in decoded form.
	internal static func length(padded_encoding_byte_length base64LengthPadded: size_t) -> size_t {
		return ((base64LengthPadded+3)/4*3)
	}

	private static func _parse_bytes_main<I>(dest_head:inout Array<UInt8>, src:inout I) throws -> (size_t, Encoded.Padding) where I:IteratorProtocol, I.Element == UInt8 {
		var valueCount:size_t = 0
		while true {
			let v_i0:UInt8
			switch (src.next()) {
				case (.some(let v0)):
					switch v0 {
						case 0x3d: // '='
							throw Error.invalidBase64EncodingCharacter(Character(UnicodeScalar(v0)))
						default:
							v_i0 = try Value(validate:v0).indexValue()
							valueCount += 1
					}
				case (.none):
					return (valueCount, .zero)
			}

			let v_i1:UInt8
			switch (src.next()) {
				case (.some(let v1)):
					v_i1 = try Value(validate:v1).indexValue()
					valueCount += 1
				case (.none):
					throw Error.invalidPaddingLength
			}

			switch (src.next()) {
				case (.some(let v2)):
					switch v2 {
						case 0x3d: // '='
							switch (src.next()) {
								case 0x3d:
									guard src.next() == nil else {
										throw Error.invalidPaddingLength
									}
									dest_head.append((v_i0 << 2) | (v_i1 >> 4))
									return (valueCount, .two)
								default:
									throw Error.invalidBase64EncodingCharacter(Character(UnicodeScalar(v2)))

							}
						default:
							let v_i2 = try Value(validate:v2).indexValue()
							valueCount += 1
							switch (src.next()) {
								case (.some(let v3)):
									switch v3 {
										case 0x3d: // '='
											dest_head.append((v_i0 << 2) | (v_i1 >> 4))
											dest_head.append(((v_i1 & 0xf) << 4) | (v_i2 >> 2))
											guard src.next() == nil else {
												throw Error.invalidPaddingLength
											}
											return (valueCount, .one)
										default:
											let v_i3 = try Value(validate:v3).indexValue()
											valueCount += 1
											dest_head.append((v_i0 << 2) | (v_i1 >> 4))
											dest_head.append(((v_i1 & 0xf) << 4) | (v_i2 >> 2))
											dest_head.append(((v_i2 & 0x3) << 6) | v_i3)
									}
								case (.none):
									throw Error.invalidPaddingLength

							}
					}
				case (.none):
					throw Error.invalidPaddingLength
			}
		}
	}

	internal static func _chunk_parse_values<I>(dest_head:inout Array<UInt8>, src:inout I) throws -> Int? where I:IteratorProtocol, I.Element == Value {
		// store the data
		guard let v_i0 = src.next()?.indexValue() else {
			return nil
		}
		let v_i1 = src.next()!.indexValue()
		switch (src.next(), src.next()) {
			case (.some(let v2), .some(let v3)):
				// store the data
				let v_i2 = v2.indexValue()
				let v_i3 = v3.indexValue()

				// apply the translation
				dest_head.append((v_i0 << 2) | (v_i1 >> 4))
				dest_head.append(((v_i1 & 0xf) << 4) | (v_i2 >> 2))
				dest_head.append(((v_i2 & 0x3) << 6) | v_i3)
				return 4
			case (.some(let v2), .none):
				// store the data
				let v_i2 = v2.indexValue()

				// apply the translation
				dest_head.append((v_i0 << 2) | (v_i1 >> 4))
				dest_head.append(((v_i1 & 0xf) << 4) | (v_i2 >> 2))
				return 3
			case (.none, .none):
				// apply the translation
				dest_head.append((v_i0 << 2) | (v_i1 >> 4))
				return 2
			default:
				fatalError("major internal error with base64 decoder")
		}
	}

	internal static func process<SV>(values:consuming SV) throws -> ([UInt8], size_t) where SV:Sequence, SV.Element == Value {
		var newArray = Array<UInt8>()
		var src = values.makeIterator()
		var inputLength:size_t = 0
		while let strideCount = try _chunk_parse_values(dest_head:&newArray, src:&src) {
			inputLength += strideCount
		}
		return (newArray, inputLength)
	}

	internal static func process<SB>(bytes:consuming SB) throws -> ([UInt8], size_t) where SB:Sequence, SB.Element == UInt8 {
		var newArray = Array<UInt8>()
		var src = bytes.makeIterator()
		let strideCount = try _parse_bytes_main(dest_head:&newArray, src:&src)
		return (newArray, strideCount.0)
	}
}

