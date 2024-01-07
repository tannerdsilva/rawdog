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
	/// thrown when the hex string is not a valid hex character.
	/// - valid hex characters are `0-9`, `a-f`, and `A-F` in ascii form.
	case invalidHexEncodingCharacter(UInt8)
	/// thrown when a hex encoded string is not a valid size for the decoding algorithm. encoded strings must be an even number of characters, since they are represented with twice as many bytes.
	case invalidEncodingSize(size_t)
}

extension Array where Element == Value {
	/// initialize a new array of hex values from a byte buffer.
	/// - throws: ``Error.invalidHexEncodingCharacter`` if the byte buffer contains a byte that is not a valid hex character.
	public init(validate data:UnsafePointer<UInt8>, count:size_t) throws {
		self = try Self(unsafeUninitializedCapacity:count, initializingWith: { valueBuffer, valueCount in
			valueCount = 0
			while valueCount < count {
				valueBuffer[valueCount] = try Value(validate:data[valueCount])
				valueCount += 1
			}
			#if DEBUG
			assert(valueCount == count)
			#endif
		})
	}

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

	public init(_ encoded:Encoded) {
		self.init(unsafeUninitializedCapacity:encoded.count, initializingWith: { valueBuffer, valueCount in
			valueCount = 0
			var seekPointer = valueBuffer.baseAddress!
			for value in encoded {
				seekPointer.initialize(to:value)
				seekPointer += 1
				valueCount += 1
			}
			#if DEBUG
			assert(valueCount == encoded.count)
			#endif
		})
	}
}

extension String {

	/// initialize a string from a hex encoded value. the resulting string will be the ascii-based hex string of representing the byte values.
	public init(_ encoded:Encoded) {
		self.init([Character](unsafeUninitializedCapacity:encoded.count, initializingWith: { charBuffer, charCount in
			charCount = 0
			var curPtr = charBuffer.baseAddress!
			for value in encoded {
				defer {
					curPtr += 1
					charCount += 1
				}
				curPtr.initialize(to:value.characterValue())
			}
		}))
	}
}

extension Array where Element == UInt8 {

	/// initialize a new byte array from a hex encoded value. the resulting byte array will be the hex-encoded ascii string of the byte array.
	public init(_ encoded:Encoded) {
		self.init([UInt8](unsafeUninitializedCapacity:encoded.count, initializingWith: { byteBuffer, byteCount in
			byteCount = 0
			var curPtr = byteBuffer.baseAddress!
			for value in encoded {
				defer {
					curPtr += 1
					byteCount += 1
				}
				curPtr.initialize(to:value.asciiValue())
			}
		}))
	}
}
