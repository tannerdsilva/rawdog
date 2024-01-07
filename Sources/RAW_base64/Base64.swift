import RAW

#if RAWDOG_BASE64_LOG
import Logging
internal func makeDefaultLogger() -> Logger {
	var logger = Logger(label:"RAW_base64")
	logger.logLevel = .trace
	return logger
}
internal var logger = makeDefaultLogger()
#endif

/// error thrown by Base64 encoding/decoding functions
public enum Error:Swift.Error {
	/// thrown when the padding length is not valid for the given Base64 encoding.
	case invalidPaddingLength
	
	/// the provided string could not be decoded.
	case invalidEncodingLength(size_t)

	/// thrown when 
	case invalidBase64EncodingCharacter(Character)
}

// encode functions
/// encode a byte array to a base64 encoded string.
public func encode(_ bytes:[UInt8], count:size_t) throws -> Encoded {
	return Encoded.from(decoded:bytes, count:count)
}
/// encode a byte array to a base64 encoded string.
public func encode(_ bytes:[UInt8]) -> Encoded {
	return Encoded.from(decoded:bytes, count:bytes.count)
}
/// encode an explicit base64 value array to a base64 encoded string (with padding).
public func encode(_ values:[Value]) throws -> Encoded {
	return try Encoded.from(encoded:values, count:values.count)
}

// decode functions
/// decode a base64 encoded string to a decoded byte array.
public func decode(_ str:String) throws -> [UInt8] {
	return try Encoded.from(encoded:str).decoded()
}
/// decode a base64 encoded byte buffer to a decoded byte array.
public func decode(_ bytes:[UInt8]) throws -> [UInt8] {
	return try Encoded.from(encoded:bytes, count:bytes.count).decoded()
}
/// decode a base64 encoded byte buffer to a decoded byte array.
public func decode(_ bytes:UnsafePointer<UInt8>, count:size_t) throws -> [UInt8] {
	return try Encoded.from(encoded:bytes, count:count).decoded()
}
public func decode(_ encoded:Encoded) -> [UInt8] {
	return encoded.decoded()
}

extension Array where Element == Value {
	/// returns an array of random hex values. the length of the array is specified by the `length` parameter.
	public static func random(length:size_t) -> Self {
		return Self(unsafeUninitializedCapacity:length, initializingWith: { valueBuffer, valueCount in
			valueCount = 0
			var seekPointer = valueBuffer.baseAddress!
			while valueCount < length {
				seekPointer.initialize(to:Value.random())
				seekPointer += 1
				valueCount += 1
			}
			#if DEBUG
			assert(valueCount == length)
			#endif
		})
	}
}

extension String {
	/// initialize a string value from a base64 encoded struct.
	public init(_ encoded:Encoded) {
		let expectedTail = encoded.padding
		let encodedLength = encoded.count + expectedTail.asSize()
		self.init([Character](unsafeUninitializedCapacity:encodedLength, initializingWith: { charBuff, charSize in
			charSize = 0
			var writePtr = charBuff.baseAddress!
			for val in encoded {
				writePtr.initialize(to:val.characterValue())
				writePtr += 1
				charSize += 1
			}
			switch expectedTail {
				case .zero: break
				case .one:
					writePtr.initialize(to:"=")
					charSize += 1
				case .two:
					writePtr.initialize(to:"=")
					writePtr += 1
					writePtr.initialize(to:"=")
					charSize += 2
			}
		}))
	}
}