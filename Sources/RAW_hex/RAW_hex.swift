// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
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
	case invalidHexEncodingCharacter(Character)
	/// thrown when a hex encoded string is not a valid size for the decoding algorithm. encoded strings must be an even number of characters, since they are represented with twice as many bytes.
	case invalidEncodingSize(size_t)
}

extension Array where Element == Value {
	/// returns an array of random hex values. the length of the array is specified by the `length` parameter.
	public static func random(count length:size_t) -> Self {
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

public func encode<A:RAW_accessible>(_ accessibleBytes:borrowing A) -> Encoded {
	accessibleBytes.RAW_access { decodedBytesToEncode in
		return Encoded(decoded_bytes:[UInt8](decodedBytesToEncode))
	}
}
public func encode(_ input:consuming [UInt8]) -> Encoded {
	return Encoded(decoded_bytes:input)
}
public func encode(_ inputByte:UnsafeBufferPointer<UInt8>) -> Encoded {
	return Encoded(decoded_bytes:[UInt8](inputByte))
}

// decode functions
/// decode a base64 encoded string to a decoded byte array.
public func decode<S>(_ str:consuming S) throws -> [UInt8] where S:Sequence, S.Element == Character {
	var buildValues = [Value]()
	for char in str {
		guard char.isASCII == true else {
			throw Error.invalidHexEncodingCharacter(char)
		}
		buildValues.append(try Value(validate:char))
	}
	return [UInt8](_decode_main_values(buildValues))
}

public func decode<S>(_ str:consuming S) throws -> [UInt8] where S:RAW_encoded_unicode {
	return try decode(String(str))
}

public func decode(_ encoded:borrowing Encoded) -> [UInt8] {
	return encoded.decoded_data
}

extension String {
	/// initialize a string from a hex encoded value. the resulting string will be the ascii-based hex string of representing the byte values.
	public init(_ encoded:consuming Encoded) {
		self = .init(_encoder_main_char(encoded))
	}
}

extension RAW_encoded_unicode {
	public init(_ encoded:consuming Encoded) {
		self.init(String(_encoder_main_char(encoded)))
	}
}
