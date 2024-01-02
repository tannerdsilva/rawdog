import RAW

/// represents a base64 encoded byte buffer
@frozen public struct Encoded {

	/// represents the tail encoding of a base64 encoded value.
	@frozen public enum Tail {
		case zero
		case one
		case two
	}

	// value buffer
	public let value_count:size_t
	public let values:[Value]

	// encoding tail
	public let tail:Tail
}

extension Encoded {

	/// initialize a base64 encoded value from its string representation.
	/// - note: this is a validating initializer, meaning that it will throw an error if the string is not a valid base64 encoding.
	public init(validate base64String:String) throws {
		// convert the string into a utf8 byte array
		let utf8Bytes = [UInt8](base64String.utf8)
		self = try Self(validate:utf8Bytes, size:utf8Bytes.count)
	}

	/// initialize a base64 encoded value from a byte buffer of utf8 bytes.
	/// - note: this is a validating initializer, meaning that it will throw an error if the byte buffer is not a valid base64 encoding.
	public init(validate bytes:UnsafePointer<UInt8>, size:size_t) throws {
		// parse for the padding characters
		let getTail = try Encoded.Tail.parse(from:bytes, byte_size:size)

		// compute the number of encoded bytes
		let encoded_byte_count = size - getTail.asSize()

		// compute the number of decoded bytes and then validate the padding length against the computed value
		let decoded_byte_count = try Decoding.decoded_byte_length(unpadded_encoding_byte_length:encoded_byte_count)
		guard Encoding.computePadding(forUnencodedByteCount:decoded_byte_count) == getTail else {
			throw Error.invalidPaddingLength
		}

		let encodedValues = try [Value](unsafeUninitializedCapacity:encoded_byte_count, initializingWith: { buffer, countup in
			countup = 0
			for i in 0..<encoded_byte_count {
				buffer[countup] = try Value(validate:bytes[i])
				countup += 1
			}
		})
		self.value_count = encoded_byte_count
		self.values = encodedValues
		self.tail = getTail
	}
}

extension Encoded:Collection {
	public typealias Index = size_t
	public typealias Element = Character
	public var startIndex:Index {
		return 0
	}
	public var endIndex:Index {
		return value_count + tail.asSize()
	}
	public func index(after i:Index) -> Index {
		return i + 1
	}
	public subscript(position:Index) -> Element {
		switch tail {
		case .zero:
			guard position < value_count else {
				fatalError("invalid index: \(position)")
			}
			return values[position].characterValue()
		case .one:
			switch position {
			case 0..<value_count:
				return values[position].characterValue()
			case value_count:
				return "="
			default:
				fatalError("invalid index: \(position)")
			}
		case .two:
			switch position {
			case 0..<value_count:
				return values[position].characterValue()
			case value_count:
				return "="
			case value_count + 1:
				return "="
			default:
				fatalError("invalid index: \(position)")
			}
		}
	}
}

extension Encoded:Sequence {
	public struct Iterator:IteratorProtocol {
	    public mutating func next() -> Character? {
			defer { position += 1 }
			switch tail {
				case .zero:
					guard position < value_count else {
						return nil
					}
					return values[position].characterValue()
				case .one:
					switch position {
					case 0..<value_count:
						return values[position].characterValue()
					case value_count:
						return "="
					default:
						return nil
					}
				case .two:
					switch position {
					case 0..<value_count:
						return values[position].characterValue()
					case value_count:
						return "="
					case value_count + 1:
						return "="
					default:
						return nil
					}
			}
	    }

		private let value_count:size_t
		private let values:[Value]
		private var position:size_t
		private let tail:Tail

		fileprivate init(value_count:size_t, values:[Value], tail:Tail) {
			self.value_count = value_count
			self.values = values
			self.position = 0
			self.tail = tail
		}
	}
	public func makeIterator() -> Iterator {
		return Iterator(value_count:value_count, values:values, tail:tail)
	}
}

extension Encoded.Tail {

	/// initialize a tail from a Value.
	internal static func parse(from bytes:UnsafePointer<UInt8>, byte_size:size_t) throws -> Self {
		var iterateBackFrom = switch byte_size {
			case 0: 0
			default: byte_size - 1
		}

		// reverse-step through the bytes until we find a non-padding character
		var stepLength = 0
		seekLoop: while iterateBackFrom > 0 {
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
		let padding = Encoded.Tail(validated:stepLength)
		// ensure that there are still normal encoding bytes to process
		guard byte_size - stepLength > 0 else {
			throw Error.invalidPaddingLength
		}
		return padding
	}

	/// initialize a tail from a size_t value.
	internal init?(validate sizeValue:size_t) {
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

	internal init(validated sizeValue:size_t) {
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
		return lhs.value_count == rhs.value_count && lhs.values == rhs.values && lhs.tail == rhs.tail
	}
}