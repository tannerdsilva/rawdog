import RAW

/// represents a valid "hex string" value. while instances of this type may be expressing a value of n bytes, their actual memory footprint is n / 2, since the data is stored intenally in its decoded form.
/// - note: this is a value type, and is immutable.
public struct Encoded {
	// encoded representation is still stored as decoded bytes for memory efficiency (takes half the space).
	// this is where the decoded data is stored, and the encoded representation is computed on the fly as needed.
	private let decoded_data:[UInt8]

	/// the encoded byte count for this value.
	private let encoded_count:size_t
}

extension Encoded {
	/// initialize an encoded value from a decoded byte sequence.
	internal init(decoded bytes:[UInt8]) {
		self.encoded_count = Encode.length(bytes.count)
		self.decoded_data = bytes
	}
}

extension Encoded {
	/// initialize an encoded value by validating an existing encoding in String form.
	public init(validate string:String) throws {
		let encodedValues = try [Value](validate:string)
		let enc_v = encodedValues.count
		self.encoded_count = enc_v
		self.decoded_data = try Decode.process(values:encodedValues, value_size:enc_v)
	}

	/// initialize an encoded value by validating an existing encoding in byte form (utf8 bytes).
	public init(validate bytes:[UInt8]) throws {
		self = try Self(validate:bytes, size:bytes.count)
	}

	/// initialize an encoded value by validating an existing encoding in byte form with size specified (utf8 bytes).
	public init(validate bytes:[UInt8], size:size_t) throws {
		let encodedValues = try [Value](validate:bytes, size:size)
		self.encoded_count = size
		self.decoded_data = try Decode.process(values:encodedValues, value_size:size)
	}
}

extension Encoded:Collection {
	public typealias Index = size_t
	public typealias Element = Character

	public var startIndex:Index {
		return 0
	}

	public var endIndex:Index {
		return Encode.length(decoded_data.count)
	}

	public func index(after i:Index) -> Index {
		return i + 1
	}

	public subscript(position:Index) -> Element {
		if position % 2 == 0 {
			return Encode.process_inline(decoded_data:decoded_data, encoded_index:position).0.characterValue()
		} else {
			return Encode.process_inline(decoded_data:decoded_data, encoded_index:position).1.characterValue()
		}
	}
}

extension Encoded:Sequence {
	/// purpose built iterator for hex encoded values. designed to ensure that compute resource is not wasted when iterating over the encoded values.
	public struct Iterator:IteratorProtocol {
		private let decoded_data:[UInt8]
		private var pendingValue:Value? = nil
		private var index = 0
		private let endIndex:Int
		
		fileprivate init(encoded:Encoded) {
			self.decoded_data = encoded.decoded_data
			self.endIndex = encoded.encoded_count
		}

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

extension Encoded:ExpressibleByStringLiteral {
	public typealias StringLiteralType = String

	public init(stringLiteral value:String) {
		self = try! Self.init(validate:value)
	}
}

extension Encoded:ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = UInt8

	public init(arrayLiteral elements:UInt8...) {
		let bytes = [UInt8](elements)
		self = try! Self(validate:bytes)
	}
}