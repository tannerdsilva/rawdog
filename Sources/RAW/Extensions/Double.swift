import struct CRAW.size_t;

extension Double:RAW_encodable, RAW_decodable, RAW_comparable {
	/// retrieves the raw IEEE 754 representation of the double.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try valFunc(RAW(ptr, MemoryLayout<UInt64>.size))
		}
	}
	
	/// initialize a double from a raw IEEE 754 representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == MemoryLayout<UInt64>.size) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Double(bitPattern:RAW_data!.load(as:UInt64.self))
	}
}

extension Float:RAW_encodable, RAW_decodable, RAW_comparable {
	/// retrieves the raw IEEE 754 representation of the float.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try valFunc(RAW(ptr, MemoryLayout<UInt32>.size))
		}
	}
	
	/// initializes a float32 from a raw IEEE 754 representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == MemoryLayout<UInt32>.size) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Float(bitPattern:RAW_data!.load(as:UInt32.self))
	}
}