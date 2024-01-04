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


	public init(validate data:UnsafePointer<UInt8>, size:size_t) throws {
		// validate that this is not an invalid value length for base64 encodings
		guard size % 4 != 1 else {
			throw Error.invalidEncodingLength(size)
		}
		self = try Self(unsafeUninitializedCapacity:size, initializingWith: { valueBuffer, valueCount in
			valueCount = 0
			var writePtr = valueBuffer.baseAddress!
			while valueCount < size {
				writePtr.initialize(to:try Value(validate:data[valueCount]))
				valueCount += 1
				writePtr += 1
			}
			#if DEBUG
			assert(valueCount == size)
			#endif
		})
	}
}

extension String {
	public init(_ encoded:Encoded) {
		let encodedLength = encoded.value_count + encoded.tail.asSize()
		self.init([Character](unsafeUninitializedCapacity:encodedLength, initializingWith: { charBuff, charSize in
			charSize = 0
			var writePtr = charBuff.baseAddress!
			for val in encoded {
				writePtr.initialize(to:val.characterValue())
				writePtr += 1
				charSize += 1
			}
			switch encoded.tail {
				case .zero: break
				case .one:
					writePtr.initialize(to:"=")
				case .two:
					writePtr.initialize(to:"=")
					writePtr += 1
					writePtr.initialize(to:"=")
			}
		}))
	}
}