/// error thrown by Base64 encoding/decoding functions
public enum Error:Swift.Error {
	/// thrown when the padding length is not valid for the given base64 encoded sequence.
	case invalidPaddingLength
	
	/// the provided string could not be decoded.
	case invalidEncodingLength(Int)

	/// thrown when a character is found while decoding that violates the specifications for base64 encoding.
	case invalidBase64EncodingCharacter(Character)
}

extension Error:CustomDebugStringConvertible {
	public var debugDescription:String {
		switch self {
			case .invalidPaddingLength:
				return "RAW_base64.Error.invalidPaddingLength"
			case .invalidEncodingLength(let foundLen):
				return "RAW_base64.Error.invalidEncodingLength(\"\(foundLen.description)\")"
			case .invalidBase64EncodingCharacter(let foundChar):
				return "RAW_base64.Error.invalidBase64EncodingCharacter(\"\(foundChar.description)\")"
		}
	}
}