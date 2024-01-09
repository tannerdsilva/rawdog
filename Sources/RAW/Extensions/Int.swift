import func CRAW.memcpy;

// extend the signed 64 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int64:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the signed 32 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int32:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the signed 16 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int16:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the signed 8 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int8:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the signed integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int:RAW_decodable, RAW_encodable, RAW_comparable, RAW_staticbuff {
	/// returns underlying memory of this value
	public func RAW_staticbuff() -> RAW_staticbuff_storetype {
		return RAW_access { buff, _ in
			return buff.load(as:RAW_staticbuff_storetype.self)
		}
	}

	/// access the underlying memory of this value
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try accessFunc(ptr, MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}
	
	/// compare two raw encoded values of this type.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		let lhsVal = self.init(bigEndian:lhs_data.loadUnaligned(as:Self.self))
		let rhsVal = self.init(bigEndian:rhs_data.loadUnaligned(as:Self.self))
		if (lhsVal < rhsVal) {
			return -1
		} else if (lhsVal > rhsVal) {
			return 1
		} else {
			return 0
		}
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bigEndian:RAW_staticbuff_storetype.loadUnaligned(as:Self.self))
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