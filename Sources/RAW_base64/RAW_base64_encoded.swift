import RAW

/// represents a base64 encoded data buffer.
public struct Encoded {

	/// represents the tail encoding length of a base64 encoded value. this is the number of '=' padding characters that are present at the end of the encoded value.
	@frozen public enum Padding {
		/// no padding characters
		case zero
		/// one padding character
		case one
		/// two padding characters
		case two
	}

	internal let decoded_count:size_t
	private let decoded_data:[UInt8]

	/// primary internal initializer. initializes an encoded value from a buffer of base64 values and a tail.
	internal init(decoded:[UInt8], decoded_count:size_t) {
		#if DEBUG
		assert(decoded_count == decoded.count)
		#endif
		self.decoded_data = decoded
		self.decoded_count = decoded_count
	}
}

extension Encoded {
	/// returns a byte array representing the decoded value of the current instance.
	public func decoded() -> [UInt8] {
		return decoded_data
	}

	/// returns the unpadded encoding length of the current instance.
	public var count:size_t {
		return Encode.unpadded_length(unencoded_byte_count:decoded_count)
	}
}

extension Encoded {
	/// initialize an encoded value from a byte buffer of unencoded bytes.
	public static func from(decoded bytes:[UInt8]) throws -> Self {
		return Self(decoded:bytes, decoded_count:bytes.count)
	}
}

extension Encoded {
	public static func from(encoded values:UnsafePointer<Value>, value_count:size_t, padding:Encoded.Padding) throws -> Self {
		let decodedBytes = try Decode.process(values:values, value_count:value_count, padding_audit:padding)
		return Self(decoded:decodedBytes.0, decoded_count:decodedBytes.1) 
	}

	/// initialize a base64 encoded value from a string representation of its value
	public static func from(encoded encString:String) throws -> Self {
		let utf8Bytes = [UInt8](encString.utf8)
		let getCount = utf8Bytes.count
		return try Self.from(encoded:utf8Bytes, size:getCount)
	}

	/// initialize a base64 encoded value from a byte buffer of utf8 bytes.
	public static func from(encoded encBytes:UnsafePointer<UInt8>, size:size_t) throws -> Self {
		let getTail = try Encoded.Padding.parse(from:encBytes, byte_size:size)

		let encoded_byte_count = size - getTail.asSize()
		let decoded_byte_count = try Decode.length(unpadded_encoding_byte_length:encoded_byte_count)
		
		guard Encode.compute_padding(unencoded_byte_count:decoded_byte_count) == getTail else {
			throw Error.invalidPaddingLength
		}
		var valSize:size_t = 0
		let encodedValues = try [Value](unsafeUninitializedCapacity:encoded_byte_count, initializingWith: { buffer, countup in
			countup = 0
			var writePtr = buffer.baseAddress!
			for i in 0..<encoded_byte_count {
				writePtr.initialize(to:try Value(validate:encBytes[i]))
				writePtr += 1
				countup += 1
			}
			valSize = countup
		})

		let decodedBytes = try Decode.process(values:encodedValues, value_count:valSize, padding_audit:getTail)

		return Self(decoded:decodedBytes.0, decoded_count:decodedBytes.1)
	}
}

extension Encoded:Collection {
	public typealias Index = size_t
	public typealias Element = Value
	public var startIndex:Index {
		return 0
	}
	public var endIndex:Index {
		return Encode.unpadded_length(unencoded_byte_count:decoded_count)
	}
	public func index(after i:Index) -> Index {
		return i + 1
	}
	public subscript(position:Index) -> Element {
		return Encode.chunk_parse_inline(decoded_bytes:self.decoded_data, decoded_byte_count:self.decoded_count, encoded_index:position)
	}
}

extension Encoded:Sequence {
	public struct Iterator:IteratorProtocol {
	    public mutating func next() -> Value? {
			guard position < encoded_count else {
				return nil
			}
			let nextValue = Encode.chunk_parse_inline(decoded_bytes:data, decoded_byte_count:data_count, encoded_index:position)
			position += 1
			return nextValue
	    }
		private let encoded_count:size_t
		private let data_count:size_t
		private let data:[UInt8]
		private var position:size_t

		fileprivate init(data:[UInt8], data_count:size_t) {
			self.data = data
			self.data_count = data_count
			self.position = 0
			self.encoded_count = Encode.unpadded_length(unencoded_byte_count: data_count)
		}
	}
	public func makeIterator() -> Iterator {
		return Iterator(data:decoded_data, data_count:decoded_count)
	}
}

extension Encoded.Padding {
	/// initialize a tail from a string encoded value buffer.
	internal static func parse(from bytes:UnsafePointer<UInt8>, byte_size:size_t) throws -> Self {
		var iterateBackFrom = switch byte_size {
			case 0: 0
			default: byte_size - 1
		}

		// reverse-step through the bytes until we find a non-padding character
		var stepLength = 0
		seekLoop: while iterateBackFrom >= 0 {
			switch stepLength {
				case 0, 1:
					switch bytes[iterateBackFrom] {
						// padding character
						case 0x3d: // =
							stepLength += 1
							iterateBackFrom -= 1
							continue seekLoop
						default: break seekLoop
					}
				case 2:
					switch bytes[iterateBackFrom] {
						// padding character
						case 0x3d:
							// a third padding character is invalid so we'll throw an error
							throw Error.invalidPaddingLength
						default: break seekLoop
					}
				default:
					fatalError("stepLength should never be greater than 2")
			}
		}
		// ensure that there are still normal encoding bytes to process
		guard byte_size - stepLength >= 0 else {
			throw Error.invalidPaddingLength
		}
		return Self(validated_length_value:stepLength)
	}

	/// initialize a tail from a size_t value.
	internal init?(validate_length_value sizeValue:size_t) {
		switch sizeValue {
		case 0:
			self = .zero
		case 1:
			self = .one
		case 2:
			self = .two
		default:
			return nil
		}
	}

	internal init(validated_length_value sizeValue:size_t) {
		switch sizeValue {
		case 0:
			self = .zero
		case 1:
			self = .one
		case 2:
			self = .two
		default:
			fatalError("invalid size value: \(sizeValue)")
		}
	}

	/// returns the size_t value of the padding
	internal func asSize() -> size_t {
		switch self {
		case .zero:
			return 0
		case .one:
			return 1
		case .two:
			return 2
		}
	}	
}

extension Encoded.Padding:Equatable, Hashable {
	/// equality operator for padding values.
	public static func == (lhs:Encoded.Padding, rhs:Encoded.Padding) -> Bool {
		switch (lhs, rhs) {
		case (.zero, .zero):
			return true
		case (.one, .one):
			return true
		case (.two, .two):
			return true
		default:
			return false
		}
	}

	/// hash function for padding values.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.asSize())
	}
}

extension Encoded:Equatable {
	/// equality operator for encoded values.
	public static func == (lhs:Encoded, rhs:Encoded) -> Bool {
		return lhs.decoded_count == rhs.decoded_count && lhs.decoded_data == rhs.decoded_data
	}
}

extension Encoded:ExpressibleByStringLiteral {
	public typealias StringLiteralType = String
	public init(stringLiteral value:String) {
		self = try! Encoded.from(encoded:value)
	}
}