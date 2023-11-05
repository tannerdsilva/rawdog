import struct CRAW.size_t;
import func CRAW.memcmp;

extension Int64:RAW_decodable, RAW_encodable, RAW_comparable {
	/// retrieves the big endian representation of the int64.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int64>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int64>.size))
			}
		}
	}
	
	/// load a big endian int64 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == MemoryLayout<Int64>.size) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int64(bigEndian:RAW_data!.load(as:Int64.self))
	}

	/// compare two raw values as if they were int64s. since these encode as big endian, we can just compare the raw bytes.
	public static func RAW_compare(_ lhs: RAW, _ rhs: RAW) -> Int32 {
		return memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Int64>.size)
	}
}

extension Int32:RAW_decodable, RAW_encodable, RAW_comparable {
	/// retrieves the big endian representation of the int32.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int32>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int32>.size))
			}
		}
	}
	
	/// load a big endian int32 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == MemoryLayout<Int32>.size) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int32(bigEndian:RAW_data!.load(as:Int32.self))
	}

	/// compares two RAW values as if they were int32s.
	public static func RAW_compare(_ lhs: RAW, _ rhs: RAW) -> Int32 {
		return memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Int32>.size)
	}
}

extension Int16:RAW_decodable, RAW_encodable, RAW_comparable {
	/// retrieves the big endian representation of the int16.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int16>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int16>.size))
			}
		}
	}
	
	/// load a big endian int16 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == MemoryLayout<Int16>.size) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int16(bigEndian:RAW_data!.load(as:Int16.self))
	}

	/// compares two RAW values as if they were int16s.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		return memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Int16>.size)
	}
}

extension Int8:RAW_decodable, RAW_encodable, RAW_comparable {
	/// retrieves the big endian representation of the int8.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int8>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int8>.size))
			}
		}
	}
	
	/// load a big endian int8 from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == MemoryLayout<Int8>.size) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int8(bigEndian:RAW_data!.load(as:Int8.self))
	}

	/// compares two RAW values as if they were int8s.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		return memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Int8>.size)
	}
}

extension Int:RAW_decodable, RAW_encodable, RAW_comparable {
	/// retrieves the big endian representation of the int.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int>.size))
			}
		}
	}
	
	/// load a big endian int from a raw representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == MemoryLayout<Int>.size) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int(bigEndian:RAW_data!.load(as:Int.self))
	}

	/// compares two RAW values as if they were ints (big endian).
	public static func RAW_compare(_ lhs: RAW, _ rhs: RAW) -> Int32 {
		return memcmp(lhs.RAW_data, rhs.RAW_data, MemoryLayout<Int>.size)
	}
}