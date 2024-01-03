import RAW

/// represents a valid "hex string" value. while instances of this type may be expressing a value of n bytes, their actual memory footprint is half of that, since the data is stored intenally in its decoded form.
/// - note: this is a value type, and is immutable.
public struct Encoded {

	// encoded representation is still stored as decoded bytes for memory efficiency (takes half the space)
	private let decoded_data:[UInt8]

}

extension Encoded {
	/// initialize an encoded value from a series of pre-parsed ``Value``'s in memory.
	@available(*, deprecated, message: "This initializer is deprecated. Use other initializers instead.")
	internal init(encoded hexValues:UnsafePointer<Value>, size:size_t) throws {
		#if RAWDOG_HEX_LOG
		logger.debug("initializing encoded value from \(size) values.", metadata:["represented_size": "\(size)", "storage_size": "\(size / 2)"])
		#endif

		self.decoded_data = try Decode.process(values:hexValues, value_size:size)
	}

	/// initialize an encoded value from a decoded byte sequence.
	@available(*, deprecated, message: "This initializer is deprecated. Use other initializers instead.")
	internal init(decoded bytes:[UInt8]) {
		self.decoded_data = bytes
	}
}

extension Encoded {
	/// initialize an encoded value by validating an existing encoding in String form.
	public init(validate string:String) throws {
		let encodedValues = try [Value](validate:string)
		self.decoded_data = try Decode.process(values:encodedValues, value_size:encodedValues.count)
	}

	/// initialize an encoded value by validating an existing encoding in byte form (utf8 bytes).
	public init(validate bytes:[UInt8]) throws {
		self = try Self(validate:bytes, size:bytes.count)
	}

	/// initialize an encoded value by validating an existing encoding in byte form with size specified (utf8 bytes).
	public init(validate bytes:[UInt8], size:size_t) throws {
		let encodedValues = try [Value](validate:bytes, size:bytes.count)
		self.decoded_data = try Decode.process(values:encodedValues, value_size:encodedValues.count)
	}
}

extension Encoded:Collection {
	public typealias Index = size_t
	public typealias Element = Value

	public var startIndex:Index {
		return 0
	}

	public var endIndex:Index {
		return [Value].encodingSize(forUnencodedByteCount:decoded_data.count)
	}

	public func index(after i:Index) -> Index {
		return i + 1
	}

	public subscript(position:Index) -> Element {
		if position % 2 == 0 {
			return RAW_hex_encode_inline(decoded_data:decoded_data, encoded_index:position).0
		} else {
			return RAW_hex_encode_inline(decoded_data:decoded_data, encoded_index:position).1
		}
	}
}

extension Encoded:Sequence {
	/// purpose built iterator for hex encoded values.
	public struct Iterator:IteratorProtocol {
		private let decoded_data:[UInt8]
		private var pendingValue:Value? = nil
		private var index = 0
		private let endIndex:Int
		
		fileprivate init(encoded:Encoded) {
			self.decoded_data = encoded.decoded_data
			self.endIndex = [Value].encodingSize(forUnencodedByteCount:decoded_data.count)
		}

		public mutating func next() -> Encoded.Element? {
			switch pendingValue {
			case .none:
				if index >= endIndex {
					return nil
				}
				let (first, second) = RAW_hex_encode_inline(decoded_data:decoded_data, encoded_index:index)
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