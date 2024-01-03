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
	return try Encoded(validate:values).decoded()
}

public func decode(_ encoded:Encoded) throws -> [UInt8] {
	return try encoded.decoded()
}

extension Array where Element == UInt8 {
	func base64Encoded() -> Encoded {
		return Encode.process(bytes:self, byte_count:self.count)
	}
}