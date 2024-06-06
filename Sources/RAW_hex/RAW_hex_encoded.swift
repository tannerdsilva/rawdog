// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import RAW

/// represents a valid "hex string" value. while instances of this type may be expressing a value of n bytes, their actual memory footprint is n / 2, since the data is stored intenally in its decoded form.
/// - note: this is a value type, and is immutable.
public struct Encoded {
	// encoded representation is still stored as decoded bytes for memory efficiency (takes half the space).
	// this is where the decoded data is stored, and the encoded representation is computed on the fly as needed.
	internal let decoded_data:[UInt8]

	/// initialize an encoded value from a decoded byte sequence.
	internal init(decoded_bytes bytes:consuming [UInt8]) {
		self.decoded_data = bytes
	}

	public init(values bytes:consuming [Value]) {
		self.decoded_data = [UInt8](_decode_main_values(bytes))
	}
}

extension Encoded {
	/// returns the byte count for this encoded value
	public var count:size_t {
		return Encode.length(decoded_data.count)
	}
}

extension Encoded:RandomAccessCollection {
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
		return Encode.length(decoded_data.count)
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
		private var decoded_data:[UInt8]
		// the pending value if there is one.
		private var pendingValue:Value? = nil
		// the current index in the encoded bytes.
		private var index = 0
		// the end index in the encoded bytes.
		private let endIndex:Int
		
		/// initialize a new iterator for the given encoded value.
		fileprivate init(encoded:Encoded) {
			self.decoded_data = encoded.decoded_data
			self.endIndex = Encode.length(encoded.decoded_data.count)
		}

		/// returns the next character in the encoded value.
		public mutating func next() -> Value? {
			switch pendingValue {
			case .none:
				guard index < endIndex else {
					return nil
				}
				let (first, second) = Encode.process_inline(decoded_data:&decoded_data, encoded_index:index)
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

	public consuming func makeIterator() -> Iterator {
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
		self = Self(decoded_bytes:try! decode(value))
	}
}

extension Encoded:ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = Value
	public init(arrayLiteral elements:Value...) {
		self = Self(values:elements)
	}
}