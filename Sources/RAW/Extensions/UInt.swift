import struct CRAW.size_t;
import func CRAW.memcmp;

extension UInt64:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize a uint64 from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = UInt64(bigEndian:RAW_data.load(as:UInt64.self))
	}

	/// initialize a uint64 from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = UInt64(bigEndian:RAW_staticbuff_storetype)
	}

	/// retrieves the big endian representation of the uint64.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try valFunc(RAW(ptr, MemoryLayout<UInt64>.size))
		}
	}
	
	/// load a big endian uint64 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard (RAW_size == MemoryLayout<UInt64>.size) else {
			return nil
		}
		self = UInt64(bigEndian:RAW_data.load(as:UInt64.self))
	}
}

extension UInt32:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize a uint32 from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = UInt32(bigEndian:RAW_data.load(as:UInt32.self))
	}

	/// initialize a uint32 from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = UInt32(bigEndian:RAW_staticbuff_storetype)
	}

	/// retrieves the big endian representation of the uint32.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try valFunc(RAW(ptr, MemoryLayout<UInt32>.size))
		}
	}
	
	/// load a big endian uint32 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard (RAW_size == MemoryLayout<UInt32>.size) else {
			return nil
		}
		self = UInt32(bigEndian:RAW_data.load(as:UInt32.self))
	}
}

extension UInt16:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize a uint16 from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = UInt16(bigEndian:RAW_data.load(as:UInt16.self))
	}

	/// initialize a uint16 from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = UInt16(bigEndian:RAW_staticbuff_storetype)
	}

	/// retrieves the big endian representation of the uint16.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try valFunc(RAW(ptr, MemoryLayout<UInt16>.size))
		}
	}
	
	/// load a big endian uint16 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard (RAW_size == MemoryLayout<UInt16>.size) else {
			return nil
		}
		self = UInt16(bigEndian:RAW_data.load(as:UInt16.self))
	}
}

extension UInt8:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize a uint8 from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = UInt8(bigEndian:RAW_data.load(as:UInt8.self))
	}

	/// initialize a uint8 from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = UInt8(bigEndian:RAW_staticbuff_storetype)
	}

	/// retrieves the raw representation of the uint8.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try valFunc(RAW(ptr, MemoryLayout<UInt8>.size))
		}
	}
	
	/// load a uint8 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard (RAW_size == MemoryLayout<UInt8>.size) else {
			return nil
		}
		self = UInt8(bigEndian:RAW_data.load(as:UInt8.self))
	}
}

extension UInt:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = Self

	/// initialize a uint from a raw representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = UInt(bigEndian:RAW_data.load(as:UInt.self))
	}

	/// initialize a uint from a raw representation in memory.
	public init(RAW_staticbuff_storetype:Self) {
		self = UInt(bigEndian:RAW_staticbuff_storetype)
	}

	/// retrieves the big endian representation of the uint.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try valFunc(RAW(ptr, MemoryLayout<UInt>.size))
		}
	}
	
	/// load a uint from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard (RAW_size == MemoryLayout<UInt>.size) else {
			return nil
		}
		self = UInt(bigEndian:RAW_data.load(as:UInt.self))
	}
}