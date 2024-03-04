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
	internal let decoded_data:[UInt8] // data buffer for the decoded value

	internal init(decoded_bytes decoded:borrowing [UInt8]) {
		self.decoded_data = copy decoded
		self.decoded_count = decoded.count
	}
	internal init(decoded_bytes decoded:UnsafeBufferPointer<UInt8>) {
		self.decoded_data = [UInt8](decoded)
		self.decoded_count = decoded.count
	}
}

extension Encoded {
	public borrowing func decodedByteCount() -> size_t {
		return decoded_count
	}
	
	public borrowing func paddedEncodingByteCount() -> size_t {
		switch padding() {
		case .zero:
			return Encode.unpadded_length(unencoded_byte_count:decoded_count)
		case .one:
			return Encode.unpadded_length(unencoded_byte_count:decoded_count) + 1
		case .two:
			return Encode.unpadded_length(unencoded_byte_count:decoded_count) + 2
		}
	}

	public borrowing func unpaddedEncodedByteCount() -> size_t {
		return Encode.unpadded_length(unencoded_byte_count:decoded_count)
	}

	public borrowing func padding() -> Encoded.Padding {
		return Encode.compute_padding(unencoded_byte_count:decoded_count)
	}
}

// encoded initializers
extension Encoded {
	public static func from(encoded encString:consuming String) throws -> Self {
		return try Self.from(encoded:encString.utf8)
	}
	
	public static func from<SB>(encoded encBytes:consuming SB) throws -> Self where SB:Sequence, SB.Element == UInt8 {
		let decodedBytes = try Decode.process(bytes:encBytes)
		return Self(decoded_bytes:decodedBytes.0)
	}

	/// initialize a base64 encoded value from a byte buffer of base64 values.
	public static func from<SV>(encoded values:consuming SV) throws -> Self where SV:Sequence, SV.Element == Value {
		let decodedBytes = try Decode.process(values:values)
		#if DEBUG
		let decoded_byte_count = try Decode.length(unpadded_encoding_byte_length:decodedBytes.1)
		assert(decoded_byte_count == decodedBytes.0.count, "decoded_byte_count (\(decoded_byte_count)) should be equal to decodedBytes.count (\(decodedBytes.0.count))")
		#endif
		return Self(decoded_bytes:decodedBytes.0)
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
		self = try! Encoded.from(encoded:elements)
	}
}

extension Encoded:ExpressibleByStringLiteral {
	public typealias StringLiteralType = String
	public init(stringLiteral value:String) {
		self = try! Encoded.from(encoded:value)
	}
}