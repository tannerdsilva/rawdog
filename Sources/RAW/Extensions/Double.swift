import func CRAW.memcpy;

extension Double:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bitPattern:RAW_decode.load(as:UInt64.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bitPattern) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<UInt64>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

extension Float:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// returns underlying memory of this value
	public func RAW_staticbuff() -> RAW_staticbuff_storetype {
		return RAW_access { buff, _ in
			return buff.load(as:RAW_staticbuff_storetype.self)
		}
	}

	/// access the underlying memory of this value
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try accessFunc(ptr, MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bitPattern:RAW_staticbuff_storetype.loadUnaligned(as:UInt32.self))
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {	
		let doubleLeft = Self(bitPattern:lhs_data.loadUnaligned(as:UInt32.self))
		let doubleRight = Self(bitPattern:rhs_data.loadUnaligned(as:UInt32.self))
		if (doubleLeft < doubleRight) {
			return -1
		} else if (doubleLeft > doubleRight) {
			return 1
		} else {
			return 0
		}
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)
}