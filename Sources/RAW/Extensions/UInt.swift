import struct CRAW.size_t;
import func CRAW.memcpy;

extension UInt64:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = Self(bigEndian:RAW_staticbuff_storetype)
	}

	/// initialize an int from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// retrieves the big endian representation of the int.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<Self>.size) { sizePtr in
				return try valFunc(ptr, sizePtr)
			}
		}
	}
	/// load a big endian int from a raw representation in memory.
	public init?(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard (RAW_size.pointee == MemoryLayout<Self>.size) else {
			return nil
		}
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// direct implementation of the ``RAW_comparable`` protocol for higher performance over the default implementation.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		if (lhs.RAW_size != rhs.RAW_size) {
			return (lhs.RAW_size < rhs.RAW_size) ? -1 : 1
		} else {
			return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, lhs.RAW_size)
		}
	}
}

extension UInt32:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = Self(bigEndian:RAW_staticbuff_storetype)
	}

	/// initialize an int from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// retrieves the big endian representation of the int.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<Self>.size) { sizePtr in
				return try valFunc(ptr, sizePtr)
			}
		}
	}
	/// load a big endian int from a raw representation in memory.
	public init?(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard (RAW_size.pointee == MemoryLayout<Self>.size) else {
			return nil
		}
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// direct implementation of the ``RAW_comparable`` protocol for higher performance over the default implementation.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		if (lhs.RAW_size != rhs.RAW_size) {
			return (lhs.RAW_size < rhs.RAW_size) ? -1 : 1
		} else {
			return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, lhs.RAW_size)
		}
	}
}

extension UInt16:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = Self(bigEndian:RAW_staticbuff_storetype)
	}

	/// initialize an int from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// retrieves the big endian representation of the int.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<Self>.size) { sizePtr in
				return try valFunc(ptr, sizePtr)
			}
		}
	}
	/// load a big endian int from a raw representation in memory.
	public init?(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard (RAW_size.pointee == MemoryLayout<Self>.size) else {
			return nil
		}
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// direct implementation of the ``RAW_comparable`` protocol for higher performance over the default implementation.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		if (lhs.RAW_size != rhs.RAW_size) {
			return (lhs.RAW_size < rhs.RAW_size) ? -1 : 1
		} else {
			return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, lhs.RAW_size)
		}
	}
}

extension UInt8:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = Self(bigEndian:RAW_staticbuff_storetype)
	}

	/// initialize an int from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// retrieves the big endian representation of the int.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<Self>.size) { sizePtr in
				return try valFunc(ptr, sizePtr)
			}
		}
	}
	/// load a big endian int from a raw representation in memory.
	public init?(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard (RAW_size.pointee == MemoryLayout<Self>.size) else {
			return nil
		}
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// direct implementation of the ``RAW_comparable`` protocol for higher performance over the default implementation.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		if (lhs.RAW_size != rhs.RAW_size) {
			return (lhs.RAW_size < rhs.RAW_size) ? -1 : 1
		} else {
			return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, lhs.RAW_size)
		}
	}
}

extension UInt:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = Self(bigEndian:RAW_staticbuff_storetype)
	}

	/// initialize an int from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// retrieves the big endian representation of the int.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<Self>.size) { sizePtr in
				return try valFunc(ptr, sizePtr)
			}
		}
	}
	/// load a big endian int from a raw representation in memory.
	public init?(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard (RAW_size.pointee == MemoryLayout<Self>.size) else {
			return nil
		}
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// direct implementation of the ``RAW_comparable`` protocol for higher performance over the default implementation.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		if (lhs.RAW_size != rhs.RAW_size) {
			return (lhs.RAW_size < rhs.RAW_size) ? -1 : 1
		} else {
			return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, lhs.RAW_size)
		}
	}
}