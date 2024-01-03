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
		self = try Self(unsafeUninitializedCapacity:getCount, initializingWith: { valueBuffer, valueCount in
			valueCount = 0
			while valueCount < getCount {
				valueBuffer[valueCount] = try Value(validate:data[valueCount])
				valueCount += 1
			}
			#if DEBUG
			assert(valueCount == getCount)
			#endif
		})
	}
}


public func encode(bytes:[UInt8], byte_count:size_t) -> Encoded {
	return Encoded.from(decoded:bytes, size:byte_count)
}

public func encode(bytes:[UInt8]) -> Encoded {
	return Encoded.from(decoded:bytes)
}

public func decode(values:UnsafePointer<Value>, value_count:size_t) throws -> [UInt8] {
	return try Decode.process(values:values, value_size:value_count)
}

public func decode( values:String) throws -> [UInt8] {
	return try Decode.process(values:[Value](validate:values), value_size:values.count)
}

public func decode(_ encoded:Encoded) throws -> [UInt8] {
	return encoded.decoded()
}

extension Array where Element == UInt8 {
	func base64Encoded() -> Encoded {
		return Encoded.from(decoded:self)
	}
}