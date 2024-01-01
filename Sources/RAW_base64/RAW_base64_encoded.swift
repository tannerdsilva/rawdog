import RAW

/// represents a base64 encoded byte buffer
@frozen public struct Encoded {

	/// represents the tail encoding of a base64 encoded value.
	@frozen public enum Tail {
		case zero
		case one
		case two
	}

	public let bytes:[Value]
	public let tail:Tail
}

extension Encoded:Collection {
	public typealias Index = size_t
	public typealias Element = Character
	public var startIndex:Index {
		return 0
	}
	public var endIndex:Index {
		return bytes.count + tail.asSize()
	}
	public func index(after i:Index) -> Index {
		return i + 1
	}
	public subscript(position:Index) -> Element {
		let byteCount = bytes.count
		let tailCount = tail.asSize()
		switch position {
		case 0..<byteCount:
			return bytes[position].characterValue()
		case byteCount..<(byteCount + tailCount):
			return "="
		default:
			fatalError("invalid index: \(position)")
		}
	}
}

extension Encoded.Tail {
	internal init(valid_size sizeValue:Value) {
		switch sizeValue {
		case .zero:
			self = .zero
		case .one:
			self = .one
		case .two:
			self = .two
		default:
			fatalError("invalid tail value: \(sizeValue)")
		}
	}

	/// initialize a tail from a size_t value.
	internal init?(validate_size sizeValue:size_t) {
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

	/// returns the size_t value of the tail
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

extension Encoded.Tail:Equatable, Hashable {

	/// equality operator for tail values.
	public static func == (lhs:Encoded.Tail, rhs:Encoded.Tail) -> Bool {
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

	/// hash function for tail values.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.asSize())
	}
}

extension Encoded:Equatable {
	/// equality operator for encoded values.
	public static func == (lhs:Encoded, rhs:Encoded) -> Bool {
		return lhs.bytes == rhs.bytes && lhs.tail == rhs.tail
	}
}