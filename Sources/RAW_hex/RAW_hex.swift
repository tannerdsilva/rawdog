import RAW

#if RAWDOG_HEX_LOG
import Logging
internal func makeDefaultLogger() -> Logger {
	var logger = Logger(label:"RAW_hex")
	logger.logLevel = .debug
	return logger
}
internal let logger = makeDefaultLogger()
#endif

/// errors related to hex encoding and decoding.
public enum Error:Swift.Error {
	/// general error that is thrown when a function returns false
	case hexDecodeFailed
	/// general error that is thrown when a function returns false
	case hexEncodeFailed
	/// thrown when the hex string is not a valid hex string.
	case invalidHexEncodingCharacter(UInt8)
	/// thrown when a hex encoded string is not a valid size for the decoding algorithm. encoded strings must be an even number of characters, since they are represented with twice as many bytes.
	case invalidEncodingSize(size_t)
}

extension Array where Element == Value {
	/// initialize a new array of hex values from a hex string.
	/// validates the contents of the string to ensure that it is a valid hex string.
	/// - parameter RAW_hex_validate_encoded: the hex string to initialize the array from.
	/// - throws: assorted errors if the hex string is not valid.
	public init(validate hexString:String) throws {
		let utf8Bytes = [UInt8](hexString.utf8)
		let getCount = utf8Bytes.count
		self = try Self(validate:utf8Bytes, size:getCount)
	}

	/// initialize a new array of hex values from a byte buffer.
	public init(validate data:UnsafePointer<UInt8>, size:size_t) throws {
		let getCount = size
		guard Self.isEncodingSizeValid(getCount) else {
			throw Error.invalidEncodingSize(getCount)
		}
		self = try Self(unsafeUninitializedCapacity:getCount, initializingWith: { valueBuffer, valueCount in
			valueCount = 0
			while valueCount < getCount {
				valueBuffer[valueCount] = try Value(validate:data[valueCount])
				valueCount += 1
			}
		})
	}
}

/// encode a byte buffer into a hex representation.
internal func RAW_hex_encode(_ data:UnsafePointer<UInt8>, _ data_size:size_t) -> [Value] {
	// determine the size of the output buffer. this is referenced a few times, so we'll just calculate it once.
	let encodingSize = [Value].encodingSize(forUnencodedByteCount:data_size)

	// assemble the output buffer. we'll use the unsafe initializer to avoid initializing the buffer twice. return the buffer.
	return [Value](unsafeUninitializedCapacity:encodingSize, initializingWith: { valueBuffer, valueCount in
		valueCount = 0
		let byteInputBuffer = UnsafeBufferPointer<UInt8>(start:data, count:data_size)
		for byte in byteInputBuffer {
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

internal func RAW_hex_encode_inline(decoded_data:UnsafePointer<UInt8>, encoded_index:size_t) -> (Value, Value) {
	#if RAWDOG_HEX_LOG
	logger.debug("encoding byte at index \(encoded_index).", metadata:["output_index": "\(encoded_index)"])
	#endif
	let byte = decoded_data[encoded_index / 2]
	let high = byte >> 4
	let low = byte & 0x0F
	return (Value(hexcharIndexValue:high), Value(hexcharIndexValue:low))
}

extension [Value] {
	internal static func isEncodingSizeValid(_ size:size_t) -> Bool {
		return size % 2 == 0
	}

	/// returns the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func encodingSize(forUnencodedByteCount byteCount:size_t) -> size_t {
		return byteCount * 2
	}

	/// returns the number of unencoded bytes that would be required to decode the current instance of ``Value`` values.
	internal static func decodedSize(forEncodedByteCount byteCount:size_t) -> size_t {
		return byteCount / 2
	}
}