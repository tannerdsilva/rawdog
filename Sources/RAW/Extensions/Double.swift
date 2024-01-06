import func CRAW.memcpy;

extension Double:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// compare two raw encoded values of this type.
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try accessFunc(UnsafeRawPointer(ptr), MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}
	
	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bitPattern:UnsafeRawPointer(RAW_staticbuff_storetype).load(as:UInt64.self))
	}

	/// encodes the value to the specified pointer.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bitPattern) { bitPatternPtr in
			// copy the bits of the UInt64
			let writeSize = MemoryLayout<UInt64.RAW_staticbuff_storetype>.size
			ptr.copyMemory(from:bitPatternPtr, byteCount:writeSize)
			return ptr.advanced(by:writeSize)
		}
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {	
		let doubleLeft = Self(bitPattern:lhs_data.assumingMemoryBound(to:UInt64.self).pointee)
		let doubleRight = Self(bitPattern:rhs_data.assumingMemoryBound(to:UInt64.self).pointee)
		if (doubleLeft < doubleRight) {
			return -1
		} else if (doubleLeft > doubleRight) {
			return 1
		} else {
			return 0
		}
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}

extension Float:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// access the underlying memory of this value
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try accessFunc(UnsafeRawPointer(ptr), MemoryLayout<Self.RAW_staticbuff_storetype>.size)
		}
	}

	/// initialize afrom the given raw buffer representation.
	public init(RAW_staticbuff_storetype: UnsafeRawPointer) {
		self.init(bitPattern:RAW_staticbuff_storetype.load(as:UInt32.self))
	}

	/// encodes the value to the specified pointer.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bitPattern) { bitPatternPtr in
			// copy the bits of the UInt64
			let writeSize = MemoryLayout<UInt32.RAW_staticbuff_storetype>.size
			ptr.copyMemory(from:bitPatternPtr, byteCount:writeSize)
			return ptr.advanced(by:writeSize)
		}
	}

	/// implements faithful comparison of the integer.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {	
		let doubleLeft = Self(bitPattern:lhs_data.assumingMemoryBound(to:UInt32.self).pointee)
		let doubleRight = Self(bitPattern:rhs_data.assumingMemoryBound(to:UInt32.self).pointee)
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