import RAW

/// error thrown by Base64 encoding/decoding functions
public enum Error:Swift.Error {
	/// thrown when the padding length is not valid for the given Base64 encoding.
	case invalidPaddingLength
	
	/// the provided string could not be decoded.
	case invalidEncodingLength(size_t)

	/// thrown when 
	case invalidBase64EncodingCharacter(Character)
}

public func encode(bytes:UnsafePointer<UInt8>, byte_count:size_t) -> Encoded {
	return Encode.process(bytes:bytes, byte_count:byte_count)
}

public func encode(bytes:[UInt8]) -> Encoded {
	return Encode.process(bytes:bytes, byte_count:bytes.count)
}

public func decode(values:UnsafePointer<Value>, value_count:size_t, padding:Encoded.Padding) throws -> [UInt8] {
	return try Decode.process(values:values, value_count:value_count, padding_audit:padding)
}

public func decode(values:String) throws -> [UInt8] {
	return try Encoded.from(encoded:values).decoded()
}

public func decode(_ encoded:Encoded) throws -> [UInt8] {
	return try encoded.decoded()
}

extension Array where Element == UInt8 {
	func base64Encoded() -> Encoded {
		return Encode.process(bytes:self, byte_count:self.count)
	}
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

