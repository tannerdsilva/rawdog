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

public func encode(_ bytes:[UInt8], byte_count:size_t) throws -> Encoded {
	#if DEBUG
	assert(byte_count == bytes.count, "byte count must match byte buffer count. \(byte_count) != \(bytes.count)")
	#endif
	return try Encoded.from(decoded:bytes)
}

public func encode(_ bytes:[UInt8]) throws -> Encoded {
	return try Encoded.from(decoded:bytes)
}

public func decode(_ str:String) throws -> [UInt8] {
	return try Encoded.from(encoded:str).decoded()
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
		#if RAWDOG_BASE64_LOG
		logger.info("initializing string from encoded value. encoded: \(encoded.count)")
		#endif
		let expectedTail = Encode.compute_padding(unencoded_byte_count:encoded.decoded_count)
		#if RAWDOG_BASE64_LOG
		logger.info("expected tail: \(expectedTail)")
		#endif
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