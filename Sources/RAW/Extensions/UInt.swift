import struct CRAW.size_t;
import func CRAW.memcpy;
import func CRAW.memcmp;

// extend the unsigned 64 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt64:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// access the underlying memory of this value
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try accessFunc(UnsafeRawPointer(ptr), MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}

	/// compare two raw encoded values of this type.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		let lhsVal = self.init(bigEndian:lhs_data.load(as:Self.self))
		let rhsVal = self.init(bigEndian:rhs_data.load(as:Self.self))
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}
	
	/// initialize afrom the given raw buffer representation.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}

// extend the unsigned 32 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt32:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// access the underlying memory of this value
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try accessFunc(UnsafeRawPointer(ptr), MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}

	/// compare two raw encoded values of this type.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		let lhsVal = self.init(bigEndian:lhs_data.load(as:Self.self))
		let rhsVal = self.init(bigEndian:rhs_data.load(as:Self.self))
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize afrom the given raw buffer representation.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)
}

// extend the unsigned 16 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt16:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// access the underlying memory of this value
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try accessFunc(UnsafeRawPointer(ptr), MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}

	/// compare two raw encoded values of this type.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		let lhsVal = self.init(bigEndian:lhs_data.load(as:Self.self))
		let rhsVal = self.init(bigEndian:rhs_data.load(as:Self.self))
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize afrom the given raw buffer representation.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8)
}

// extend the unsigned 8 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt8:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// access the underlying memory of this value
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try accessFunc(UnsafeRawPointer(ptr), MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}

	/// compare two raw encoded values of this type.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		let lhsVal = self.init(bigEndian:lhs_data.load(as:Self.self))
		let rhsVal = self.init(bigEndian:rhs_data.load(as:Self.self))
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize afrom the given raw buffer representation.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8)
}

// extend the unsigned integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// compare two raw encoded values of this type.
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try accessFunc(UnsafeRawPointer(ptr), MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}

	/// compare two raw encoded values of this type.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		let lhsVal = self.init(bigEndian:lhs_data.load(as:Self.self))
		let rhsVal = self.init(bigEndian:rhs_data.load(as:Self.self))
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize afrom the given raw buffer representation.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	#if arch(arm64) || arch(x86_64)
	// 64 bit support
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
	#else
	// 32 bit support
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)
	#endif
}