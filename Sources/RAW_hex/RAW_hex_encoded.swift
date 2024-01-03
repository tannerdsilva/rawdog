import RAW

/// represents a valid "hex string" value. while instances of this type may be expressing a value of n bytes, their actual memory footprint is n / 2, since the data is stored intenally in its decoded form.
/// - note: this is a value type, and is immutable.
public struct Encoded<D> {
	// encoded representation is still stored as decoded bytes for memory efficiency (takes half the space).
	// this is where the decoded data is stored, and the encoded representation is computed on the fly as needed.
	private let decoded_data:[UInt8]
	private let decoded_count:size_t

	/// the encoded byte count for this value.
	private let encoded_count:size_t

	/// initialize an encoded value from a decoded byte sequence.
	internal init(decoded_bytes bytes:[UInt8], decoded_size:size_t) {
		self.encoded_count = Encode.length(bytes.count)
		self.decoded_data = bytes
		self.decoded_count = decoded_size
	}
}

extension Encoded {
	/// returns the decoded byte sequence for this encoded value.
	public func decoded() -> [UInt8] {
		return decoded_data
	}
}

// encoded initializers
extension Encoded {
	/// initialize an encoded value by validating an existing encoding in String form.
	public static func from(encoded string:String) throws -> Self {
		let encodedValues = try [Value](validate:string)
		let enc_v = encodedValues.count
		return Self(decoded_bytes:try Decode.process(values:encodedValues, value_size:enc_v), decoded_size:enc_v)
	}

	/// initialize an encoded value by validating an existing encoding in byte form (utf8 bytes).
	public static func from(encoded bytes:[UInt8]) throws -> Self {
		let bytesCount = bytes.count
		return try Self.from(encoded:bytes, size:bytesCount)
	}

	/// initialize an encoded value by validating an existing encoding in byte form with size specified (utf8 bytes).
	public static func from(encoded bytes:[UInt8], size:size_t) throws -> Self {
		let bytesCount = size
		// validate that all of the bytes are valid hex characters.
		let encodedValues = try [Value](validate:bytes, size:bytesCount)
		let enc_v = encodedValues.count
		// initialize based on the decoded values.
		return Self(decoded_bytes:try Decode.process(values:encodedValues, value_size:enc_v), decoded_size:enc_v)
	}
}

// decoded initializers
extension Encoded {
	/// initialize an encoded value by validating an existing decoding in byte form (utf8 bytes).
	public static func from(decoded bytes:[UInt8]) -> Self {
		let bytesCount = bytes.count
		return Self(decoded_bytes:bytes, decoded_size:bytesCount)
	}

	/// initialize an encoded value by validating an existing decoding in byte form with size specified (utf8 bytes).
	public static func from(decoded bytes:[UInt8], size:size_t) -> Self {
		let bytesCount = size
		return Self(decoded_bytes:bytes, decoded_size:bytesCount)
	}
}

extension Encoded:Collection {
	/// ``Encoded`` strides through memory using the size_t type.
	public typealias Index = size_t
	
	/// ``Encoded`` values are represented as a collection of ``Character`` values.
	public typealias Element = Character

	/// the starting index for this collection is always 0.
	public var startIndex:Index {
		return 0
	}

	/// the ending index for this collection is always the encoded byte count.
	public var endIndex:Index {
		return encoded_count
	}

	/// the index after the given index.
	public func index(after i:Index) -> Index {
		return i + 1
	}

	/// returns the character at the given index.
	public subscript(position:Index) -> Element {
		if position % 2 == 0 {
			return Encode.process_inline(decoded_data:decoded_data, encoded_index:position).0.characterValue()
		} else {
			return Encode.process_inline(decoded_data:decoded_data, encoded_index:position).1.characterValue()
		}
	}
}

extension Encoded:Sequence {
	/// purpose built iterator for hex encoded values. designed to ensure that compute resource is not wasted when iterating over the encoded values. no double-dipping here.
	public struct Iterator:IteratorProtocol {
		// the decoded bytes.
		private let decoded_data:[UInt8]
		// the pending value if there is one.
		private var pendingValue:Value? = nil
		// the current index in the encoded bytes.
		private var index = 0
		// the end index in the encoded bytes.
		private let endIndex:Int
		
		/// initialize a new iterator for the given encoded value.
		fileprivate init(encoded:Encoded) {
			self.decoded_data = encoded.decoded_data
			self.endIndex = encoded.encoded_count
		}

		/// returns the next character in the encoded value.
		public mutating func next() -> Encoded.Element? {
			switch pendingValue {
			case .none:
				if index >= endIndex {
					return nil
				}
				let (first, second) = Encode.process_inline(decoded_data:decoded_data, encoded_index:index)
				pendingValue = second
				index += 1
				return first.characterValue()
			case .some(let value):
				pendingValue = nil
				index += 1
				return value.characterValue()
			}
		}
	}

	public func makeIterator() -> Iterator {
		return Iterator(encoded:self)
	}
}

extension Encoded:Hashable, Equatable {
	/// equality operator for encoded values.
	public static func == (lhs:Encoded, rhs:Encoded) -> Bool {
		return lhs.decoded_data == rhs.decoded_data
	}

	/// hash function for encoded values.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.decoded_data)
	}
}

extension Encoded:ExpressibleByStringLiteral {
	public typealias StringLiteralType = String

	public init(stringLiteral value:String) {
		self = try! Self.from(encoded:value)
	}
}

extension Encoded:ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = UInt8

	public init(arrayLiteral elements:UInt8...) {
		let bytes = [UInt8](elements)
		self = try! Self.from(encoded:bytes)
	}
}