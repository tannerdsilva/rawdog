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

/// encode a bytestream representatin to a base64 string.
/// - parameter bytes: the byte representation to encode.
/// - throws: ``Error.encodingError`` if the byte representation could not be encoded. this should never be thrown under normal operating conditions.
public func encode<RE>(bytes rawBytes:RE) throws -> Encoded where RE:RAW_encodable {
	let getBuff = [UInt8](RAW_encodable:rawBytes)
	let buffSize = getBuff.count
	return Encoding.encode(bytes:getBuff, byte_size:buffSize)
}

// public func base64_decode_using_maps(ptr:UnsafeRaw)