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

	// count is stored as to not invoke the count property on the decoded_data array (constant lookup vs 0(n))
	internal let decoded_count:size_t
	private let decoded_data:[UInt8] // data buffer for the decoded value

	/// primary internal initializer. initializes an encoded value from a buffer of base64 values and a tail.
	internal init(decoded_bytes decoded:UnsafePointer<UInt8>, decoded_count:size_t) {
		self.decoded_data = [UInt8](UnsafeBufferPointer<UInt8>(start:decoded, count:decoded_count))
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

	/// returns the number of padding characters that are required to encode the current instance as a string.
	public var padding:Encoded.Padding {
		return Encode.compute_padding(unencoded_byte_count:decoded_count)
	}
}

// decoded initializers
extension Encoded {
	/// initialize an encoded value from a byte buffer of unencoded bytes.
	public static func from(decoded bytes:[UInt8], count:size_t) -> Self {
		return Self(decoded_bytes:bytes, decoded_count:bytes.count)
	}
}

// encoded initializers
extension Encoded {
	public static func from(encoded encString:String) throws -> Self {
		return try Self.from(encoded:encString.unicodeScalars)
	}

	/// initialize a base64 encoded value from a string representation of its value
	public static func from(encoded encString:String.UnicodeScalarView) throws -> Self {
		let getCount = encString.count
		return try Self.from(encoded:try [UInt8](unsafeUninitializedCapacity:getCount, initializingWith: { buff, buffcount in
			buffcount = 0
			var iterator = encString.makeIterator()
			var curItem:UnicodeScalar? = iterator.next()
			var writeHead = buff.baseAddress!
			while curItem != nil {
				defer {
					curItem = iterator.next()
				}
				guard curItem!.isASCII == true else {
					throw Error.invalidBase64EncodingCharacter(Character(curItem!))
				}
				writeHead.initialize(to:UInt8(curItem!.value))
				writeHead += 1
				buffcount += 1
			}
		}), count:getCount)
	}

	/// initialize a base64 encoded value from a byte buffer of utf8 bytes.
	/// - NOTE: padding characters in the encoded byte buffer are parsed and validated by this function.
	public static func from(encoded encBytes:UnsafePointer<UInt8>, count:size_t) throws -> Self {
		let getTail = try Encoded.Padding.parse(from:encBytes, byte_size:count)

		let encoded_byte_count = count - getTail.asSize()
		let decoded_byte_count = try Decode.length(unpadded_encoding_byte_length:encoded_byte_count)
		
		guard Encode.compute_padding(unencoded_byte_count:decoded_byte_count) == getTail else {
			throw Error.invalidPaddingLength
		}
		let decodedBytes = try Decode.process(bytes:encBytes, byte_count:encoded_byte_count, padding_audit:getTail)
		#if DEBUG
		assert(decoded_byte_count == decodedBytes.1, "decoded_byte_count (\(decoded_byte_count)) should be equal to decodedBytes.1 (\(decodedBytes.1))")
		#endif
		return Self(decoded_bytes:decodedBytes.0, decoded_count:decodedBytes.1)
	}

	/// initialize a base64 encoded value from a byte buffer of base64 values.
	/// - NOTE: padding is not handled by this function, as this value is not encompassed by the Value type.
	public static func from(encoded values:UnsafePointer<Value>, count:size_t) throws -> Self {
		let decodedBytes = try Decode.process(values:values, value_count:count)
		#if DEBUG
		let decoded_byte_count = try Decode.length(unpadded_encoding_byte_length:count)
		assert(decoded_byte_count == decodedBytes.1, "decoded_byte_count (\(decoded_byte_count)) should be equal to decodedBytes.1 (\(decodedBytes.1))")
		#endif
		return Self(decoded_bytes:decodedBytes.0, decoded_count:decodedBytes.1)
	}
}

extension Encoded:Sequence {
	public struct Iterator:IteratorProtocol {
		public mutating func next() -> Value? {
			guard position < encoded_count else {
				return nil
			}
			defer {
				position += 1
			}
			return Encode.chunk_parse_inline(decoded_bytes:&data, decoded_byte_count:data_count, encoded_index:position)
		}
		private let encoded_count:size_t
		private let data_count:size_t
		private var data:[UInt8]
		private var position:size_t
		fileprivate init(data:[UInt8], data_count:size_t) {
			#if DEBUG
			assert(data_count == data.count, "data_count (\(data_count)) should be equal to data.count (\(data.count))")
			#endif
			self.data = data
			self.data_count = data_count
			self.position = 0
			self.encoded_count = Encode.unpadded_length(unencoded_byte_count:data_count)
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

extension Encoded:ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = Value
	public init(arrayLiteral elements:Value...) {
		self = try! Encoded.from(encoded:elements, count:elements.count)
	}
}

extension Encoded:ExpressibleByStringLiteral {
	public typealias StringLiteralType = String
	public init(stringLiteral value:String) {
		self = try! Encoded.from(encoded:value)
	}
}