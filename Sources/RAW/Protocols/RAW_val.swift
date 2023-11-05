import func CRAW.memcmp;
import struct CRAW.size_t;

/// represents a raw binary value of a specified length
public protocol RAW_val:Hashable, Collection, Sequence, RAW_encodable {
	/// pointer to the raw data representation.
	var RAW_data:UnsafeRawPointer? { get }
	/// the length of the data value.
	var RAW_size:size_t { get }
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided RAW_val
	init(RAW_data:UnsafeRawPointer?, RAW_size:size_t)
	/// loads the value of the given type from the ``RAW_val``. the ``RAW_val`` is consumed, and the returned value is the loaded value and the remaining ``RAW_val`` data.
	func consume<T>(_ type:T.Type) -> (T, RAW)? where T:RAW_decodable
}

// convenience initializers for RAW.
extension RAW_val {
	/// convenience initializer that initializes a new RAW_val with the given data pointer and size.
	public init<I>(_ data:UnsafeRawPointer?, _ size:I) where I:BinaryInteger {
		self.init(RAW_data:data, RAW_size:size_t(size))
	}
	/// convenience initializer that initializes a new RAW_val with the given data pointer and size.
	public init<I>(_ size:I, _ data:UnsafeRawPointer?) where I:BinaryInteger {
		self.init(RAW_data:data, RAW_size:size_t(size))
	}
}

extension RAW_val {
	/// ``RAW_val``'s can be encoded into themselves.
	public func asRAW_val<R>(_ valFunc: (RAW) throws -> R) rethrows -> R {
		try valFunc(RAW(RAW_data, RAW_size))
	}
}

extension RAW_val {
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided RAW_val
	/// - parameter RAW_val: the RAW_val that describes the memory region
	public init<R>(_ RAW_val:R) where R:RAW_val {
		self.init(RAW_data:RAW_val.RAW_data, RAW_size:RAW_val.RAW_size)
	}
}

// convenience static functions.
extension RAW_val {
	/// returns a ``RAW_val`` conformant object that represents a "null value". the returned data size is zero, and the data pointer is nil.
	public static func nullValue() -> Self {
		return Self(0, nil)
	}
}

extension RAW_val {
	/// loads a RAW_decodable type from the given ``RAW_val``. the ``RAW_val`` is consumed, and the returned value is the loaded value and the remaining ``RAW_val`` data.
	public func consume<T>(_ type:T.Type) -> (T, RAW)? where T:RAW_decodable {
		let size = MemoryLayout<T>.size
		guard self.RAW_size >= size else {
			return nil
		}
		guard self.RAW_data != nil else {
			return nil
		}
		let value = T(RAW_size:size, RAW_data:self.RAW_data)
		guard value != nil else {
			return nil
		}
		return (value!, RAW(self.RAW_size - size, self.RAW_data!.advanced(by:Int(size))))
	}
}

// implements equatable and hashable.
extension RAW_val {
	/// hashable implementation based on the byte contents of the ``RAW_val``.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(bytes:UnsafeRawBufferPointer(start:self.RAW_data, count:Int(self.RAW_size)))
	}
	/// this implementation has no correlation to the custom sort protocols that 
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.asRAW_val { lhs in
			return rhs.asRAW_val { rhs in
				return memcmp(lhs.RAW_data, rhs.RAW_data, lhs.RAW_size) == 0
			}
		}
	}
}