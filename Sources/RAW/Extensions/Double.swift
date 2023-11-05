import struct CRAW.size_t;

extension Double:RAW_encodable, RAW_decodable, RAW_comparable {
	/// retrieves the raw IEEE 754 representation of the double.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt64>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<UInt64>.size))
			}
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

	public static func RAW_compare(_ lhs: RAW, _ rhs: RAW) -> Int32 {
		let lhsD = Self(RAW_size:lhs.RAW_size, RAW_data:lhs.RAW_data)!
		let rhsD = Self(RAW_size:rhs.RAW_size, RAW_data:rhs.RAW_data)!
		return (lhsD < rhsD) ? -1 : ((lhsD > rhsD) ? 1 : 0)
	}
}

extension Float:RAW_encodable, RAW_decodable, RAW_comparable {
	/// retrieves the raw IEEE 754 representation of the float.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt32>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<UInt32>.size))
			}
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

	public static func RAW_compare(_ lhs: RAW, _ rhs: RAW) -> Int32 {
		let lhsD = Self(RAW_size:lhs.RAW_size, RAW_data:lhs.RAW_data)!
		let rhsD = Self(RAW_size:rhs.RAW_size, RAW_data:rhs.RAW_data)!
		return (lhsD < rhsD) ? -1 : ((lhsD > rhsD) ? 1 : 0)
	}
}