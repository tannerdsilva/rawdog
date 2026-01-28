// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import RAW

// encode functions
/// encode a byte array to a base64 encoded string.
public func encode<A:RAW_accessible>(_ accessible:borrowing A) -> Encoded {
	accessible.RAW_access { encodeBytes in
		return Encoded(decoded_bytes:encodeBytes)
	}
}
public func encode(_ inputByte:UnsafeBufferPointer<UInt8>) -> Encoded {
	return Encoded(decoded_bytes:inputByte)
}

/// encode an explicit base64 value array to a base64 encoded string (with padding).
public func encode(_ values:consuming [Value]) throws -> Encoded {
	return try Encoded.from(encoded:values)
}

// decode functions
/// decode a base64 encoded string to a decoded byte array.
public func decode(_ str:consuming String) throws -> [UInt8] {
	return try Encoded.from(encoded:str).decoded_data
}

public func decode<S>(_ str:consuming S) throws -> [UInt8] where S:RAW_encoded_unicode {
	return try decode(String(str))
}

public func decode(_ encoded:borrowing Encoded) -> [UInt8] {
	return encoded.decoded_data
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
	public init(_ encoded:consuming Encoded) {
		let expectedTail = encoded.padding()
		let encodedLength = encoded.unpaddedEncodedByteCount() + expectedTail.asSize()
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