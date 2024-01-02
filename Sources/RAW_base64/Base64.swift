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

extension Array where Element == Value {
}