import struct CRAW.size_t;

extension Int64:RAW_decodable, RAW_encodable {
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
}

extension Int32:RAW_decodable, RAW_encodable {
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
}

extension Int16:RAW_decodable, RAW_encodable {
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
}

extension Int8:RAW_decodable, RAW_encodable {
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
}

extension Int:RAW_decodable, RAW_encodable {
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
}