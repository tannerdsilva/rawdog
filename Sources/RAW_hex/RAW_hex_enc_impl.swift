import RAW
internal struct Encode {

	/// computes the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func length(_ bytes:size_t) -> size_t {
		return bytes * 2
	}

	/// encode a byte buffer into a hex representation.
	internal static func process(bytes:UnsafePointer<UInt8>, byte_count:size_t) -> [Value] {
		// determine the size of the output buffer. this is referenced a few times, so we'll just calculate it once.
		let encodingSize = Encode.length(byte_count)

		// assemble the output buffer. we'll use the unsafe initializer to avoid initializing the buffer twice. return the buffer.
		return [Value](unsafeUninitializedCapacity:encodingSize, initializingWith: { valueBuffer, valueCount in
			valueCount = 0
			for byte in UnsafeBufferPointer<UInt8>(start:bytes, count:byte_count) {
				let high = byte >> 4
				let low = byte & 0x0F
				valueBuffer[valueCount] = Value(hexcharIndexValue:high)
				valueCount += 1
				valueBuffer[valueCount] = Value(hexcharIndexValue:low)
				valueCount += 1
			}
			valueCount = encodingSize
		})
	}

	internal static func process_inline(decoded_data:UnsafePointer<UInt8>, encoded_index:size_t) -> (Value, Value) {
		let byte = decoded_data[encoded_index / 2]
		let high = byte >> 4
		let low = byte & 0x0F
		return (Value(hexcharIndexValue:high), Value(hexcharIndexValue:low))
	}
}