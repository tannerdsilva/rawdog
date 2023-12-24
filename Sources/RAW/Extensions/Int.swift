import func CRAW.memcpy;

// extend the signed 64 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int64:RAW_decodable, RAW_encodable, RAW_comparable, RAW_staticbuff {
	/// encodes the value to the specified pointer.
	public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare<V>(_ lhs:V, _ rhs:V) -> Int32 where V : RAW_val {
		let lhsVal = Self(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr)
		let rhsVal = Self(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr)
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize a UInt64 from its big endian representation in memory.
	public init(RAW_staticbuff_storetype:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}

// extend the signed 32 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int32:RAW_decodable, RAW_encodable, RAW_comparable, RAW_staticbuff {
	/// encodes the value to the specified pointer.
	public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare<V>(_ lhs:V, _ rhs:V) -> Int32 where V : RAW_val {
		let lhsVal = Self(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr)
		let rhsVal = Self(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr)
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize a UInt64 from its big endian representation in memory.
	public init(RAW_staticbuff_storetype:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// adds the size of the raw memory representation to the given pointer.
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)
}

// extend the signed 16 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int16:RAW_decodable, RAW_encodable, RAW_comparable, RAW_staticbuff {
	/// encodes the value to the specified pointer.
	public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare<V>(_ lhs:V, _ rhs:V) -> Int32 where V : RAW_val {
		let lhsVal = Self(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr)
		let rhsVal = Self(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr)
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize a UInt64 from its big endian representation in memory.
	public init(RAW_staticbuff_storetype:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8)
}

// extend the signed 8 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int8:RAW_decodable, RAW_encodable, RAW_comparable, RAW_staticbuff {
	/// encodes the value to the specified pointer.
	public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare<V>(_ lhs:V, _ rhs:V) -> Int32 where V : RAW_val {
		let lhsVal = Self(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr)
		let rhsVal = Self(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr)
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize a UInt64 from its big endian representation in memory.
	public init(RAW_staticbuff_storetype:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8)
}

// extend the signed integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int:RAW_decodable, RAW_encodable, RAW_comparable, RAW_staticbuff {
	/// encodes the value to the specified pointer.
	public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		ptr.assumingMemoryBound(to:Self.self).pointee = self.bigEndian
		return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare<V>(_ lhs:V, _ rhs:V) -> Int32 where V : RAW_val {
		let lhsVal = Self(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr)
		let rhsVal = Self(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr)
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize a UInt64 from its big endian representation in memory.
	public init(RAW_staticbuff_storetype:UnsafeRawPointer) {
		self = Self(bigEndian:RAW_staticbuff_storetype.load(as:Self.self))
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