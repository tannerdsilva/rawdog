import struct CRAW.size_t;

extension Double:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = UInt64

	/// initialize a double from a raw IEEE 754 representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Double(bitPattern:RAW_data.load(as:UInt64.self))
	}

	/// initialize a double from a raw IEEE 754 representation in memory.
	public init(RAW_staticbuff_storetype:UInt64) {
		self = Double(bitPattern:RAW_staticbuff_storetype)
	}

	/// retrieves the raw IEEE 754 representation of the double.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try valFunc(ptr, MemoryLayout<UInt64>.size)
		}
	}
	
	/// initialize a double from a raw IEEE 754 representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard (RAW_size == MemoryLayout<UInt64>.size) else {
			return nil
		}
		self = .init(RAW_data:RAW_data)
	}
}

extension Float:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = UInt32

	/// initialize a double from a raw IEEE 754 representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Float(bitPattern:RAW_data.load(as:UInt32.self))
	}

	public init(RAW_staticbuff_storetype:UInt32) {
		self = Float(bitPattern:RAW_staticbuff_storetype)
	}

	/// retrieves the raw IEEE 754 representation of the float.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try valFunc(ptr, MemoryLayout<UInt32>.size)
		}
	}
	
	/// initializes a float32 from a raw IEEE 754 representation in memory.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard (RAW_size == MemoryLayout<UInt32>.size) else {
			return nil
		}
		self = .init(RAW_data:RAW_data)
	}
}