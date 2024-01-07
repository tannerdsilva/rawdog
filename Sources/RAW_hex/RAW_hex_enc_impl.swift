import RAW
internal struct Encode {

	/// computes the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func length(_ bytes:size_t) -> size_t {
		return bytes * 2
	}

	internal static func process_inline(decoded_data:UnsafePointer<UInt8>, encoded_index:size_t) -> (Value, Value) {
		let byte = decoded_data[encoded_index / 2]
		let high = byte >> 4
		let low = byte & 0x0F
		return (Value(hexcharIndexValue:high), Value(hexcharIndexValue:low))
	}
}