import RAW

/// represents a valid "hex string" value. while instances of this type may be expressing a value of n bytes, their actual memory footprint is n / 2, since the data is stored intenally in its decoded form.
/// - note: this is a value type, and is immutable.
public struct Encoded {
	// encoded representation is still stored as decoded bytes for memory efficiency (takes half the space).
	// this is where the decoded data is stored, and the encoded representation is computed on the fly as needed.
	private let decoded_data:[UInt8]
	private let decoded_count:size_t

	/// the encoded byte count for this value.
	private let encoded_count:size_t

	/// initialize an encoded value from a decoded byte sequence.
	fileprivate init(decoded_bytes bytes:[UInt8], decoded_size:size_t) {
		#if DEBUG
		assert(decoded_size == bytes.count, "decoded size must match decoded bytes count. \(decoded_size) != \(bytes.count)")
		#endif

		self.encoded_count = Encode.length(decoded_size)
		self.decoded_data = bytes
		self.decoded_count = decoded_size
	}
}

extension Encoded {
	/// returns the decoded byte sequence for this encoded value.
	public func decoded() -> [UInt8] {
		return decoded_data
	}

	/// returns the byte count for this encoded value
	public var count:size_t {
		return encoded_count
	}
}

// decoded initializers
extension Encoded {
	/// initialize a hex encoded value from a byte buffer of unencoded bytes
	public static func from(decoded bytes:[UInt8]) -> Self {
		return Self(decoded_bytes:bytes, decoded_size:bytes.count)
	}
}

// encoded initializers
extension Encoded {
	/// initialize an encoded value by validating an existing encoding in String form.
	public static func from(encoded string:String) throws -> Self {
		return try Self.from(encoded:[UInt8](string.utf8))
	}

	/// initialize an encoded value by validating an existing encoding in byte form (utf8 bytes).
	public static func from(encoded bytes:[UInt8]) throws -> Self {
		return try Self.from(encoded:bytes, size:bytes.count)
	}

	/// initialize an encoded value by validating an existing encoding in byte form with size specified (utf8 bytes).
	public static func from(encoded bytes:UnsafePointer<UInt8>, size:size_t) throws -> Self {
		// validate that all of the bytes are valid hex characters.
		let encodedValues = try [Value](validate:bytes, size:size)
		#if DEBUG
		let enc_v = encodedValues.count
		assert(enc_v == size, "encoded values count must match encoded bytes count. \(enc_v) != \(size)")
		#endif
		// initialize based on the decoded values.
		return Self.from(encoded:encodedValues, size:size)
	}
	
	/// initialize an encoded value by validating an existing encoding in byte form with size specified (utf8 bytes).
	public static func from(encoded values:UnsafePointer<Value>, size:size_t) -> Self {
		// initialize based on the decoded values.
		let decodedBytes = Decode.process(values:values, value_size:size)
		return Self(decoded_bytes:decodedBytes.0, decoded_size:decodedBytes.1)
	}

	public static func from(encoded values:[Value]) throws -> Self {
		let valuesCount = values.count
		guard valuesCount % 2 == 0 else {
			throw Error.invalidEncodingSize(valuesCount)
		}
		return Self.from(encoded:values, size:valuesCount)
	}
}

extension Encoded:Collection {
	/// ``Encoded`` strides through memory using the size_t type.
	public typealias Index = size_t
	
	/// ``Encoded`` values are represented as a collection of ``Character`` values.
	public typealias Element = Value

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
			return Encode.process_inline(decoded_data:decoded_data, encoded_index:position).0
		} else {
			return Encode.process_inline(decoded_data:decoded_data, encoded_index:position).1
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
		public mutating func next() -> Value? {
			switch pendingValue {
			case .none:
				guard index < endIndex else {
					return nil
				}
				let (first, second) = Encode.process_inline(decoded_data:decoded_data, encoded_index:index)
				pendingValue = second
				index += 1
				return first
			case .some(let value):
				pendingValue = nil
				index += 1
				return value
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
		guard value.count % 2 == 0 else {
			fatalError("encoded values must be an even number of characters.")
		}

		self = try! Self.from(encoded:value)
	}
}

extension Encoded:ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = Value

	public init(arrayLiteral elements:Value...) {
		var buildValues:[Value] = []
		for element in elements {
			buildValues.append(element)
		}

		guard elements.count % 2 == 0 else {
			fatalError("encoded values must be an even number of characters.")
		}

		self = Self.from(encoded:buildValues, size:buildValues.count)
	}
}