import struct CRAW.size_t;
import func CRAW.memcpy;

// extend the unsigned 64 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt64:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:RAW_staticbuff_storetype) {
		// expose the raw bytes of the storage type.
		self = withUnsafePointer(to:RAW_staticbuff_storetype) { ptr in
			// initialize based on the big endian representation of the storage type.
			return Self(bigEndian:ptr.withMemoryRebound(to:Self.self, capacity:1) { ptr in
				return ptr.pointee
			})
		}
	}

	/// initialize an int from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_data.load(as:Self.self))
	}

	/// retrieves the big endian representation of the int.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<RAW_staticbuff_storetype>.size) { sizePtr in
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
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Self>.size)
	}
}

// extend the unsigned 32 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt32:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:RAW_staticbuff_storetype) {
		self = withUnsafePointer(to:RAW_staticbuff_storetype) { ptr in
			return Self(bigEndian:ptr.withMemoryRebound(to:Self.self, capacity:1) { ptr in
				return ptr.pointee
			})
		}
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
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Self>.size)
	}
}

// extend the unsigned 16 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt16:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8)

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:RAW_staticbuff_storetype ) {
		self = withUnsafePointer(to:RAW_staticbuff_storetype) { ptr in
			return Self(bigEndian:ptr.withMemoryRebound(to:Self.self, capacity:1) { ptr in
				return ptr.pointee
			})
		}
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
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Self>.size)
	}
}

// extend the unsigned 8 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt8:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8)

	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:RAW_staticbuff_storetype) {
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
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Self>.size)
	}
}

// extend the unsigned integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	#if arch(arm64) || arch(x86_64)
	// 64 bit support
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
	#else
	// 32 bit support
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)
	#endif
	
	/// initialize an int from a raw representation in memory.
	public init(RAW_staticbuff_storetype:RAW_staticbuff_storetype) {
		self = withUnsafePointer(to:RAW_staticbuff_storetype) { ptr in
			return Self(bigEndian:ptr.withMemoryRebound(to:Self.self, capacity:1) { ptr in
				return ptr.pointee
			})
		}
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
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		return RAW_memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Self>.size)
	}
}