import func CRAW.memcpy;

// extend the signed 64 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int64:RAW_convertible_fixed, RAW_comparable_fixed {
	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
		let lhs = Self(RAW_decode:lhs_data)!
		let rhs = Self(RAW_decode:rhs_data)!
		if lhs < rhs {
			return -1
		} else if lhs > rhs {
			return 1
		} else {
			return 0
		}
	}

	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.loadUnaligned(as:Self.self))
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
extension Int32:RAW_convertible_fixed, RAW_comparable_fixed {
	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
		let lhs = Self(RAW_decode:lhs_data)!
		let rhs = Self(RAW_decode:rhs_data)!
		if lhs < rhs {
			return -1
		} else if lhs > rhs {
			return 1
		} else {
			return 0
		}
	}

	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.loadUnaligned(as:Self.self))
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
extension Int16:RAW_convertible_fixed, RAW_comparable_fixed {
	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
		let lhs = Self(RAW_decode:lhs_data)!
		let rhs = Self(RAW_decode:rhs_data)!
		if lhs < rhs {
			return -1
		} else if lhs > rhs {
			return 1
		} else {
			return 0
		}
	}

	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.loadUnaligned(as:Self.self))
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
extension Int8:RAW_convertible_fixed, RAW_comparable_fixed {
	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
		let lhs = Self(RAW_decode:lhs_data)!
		let rhs = Self(RAW_decode:rhs_data)!
		if lhs < rhs {
			return -1
		} else if lhs > rhs {
			return 1
		} else {
			return 0
		}
	}

	public init?(RAW_decode: UnsafeRawPointer) {
		self = RAW_decode.load(as:Self.self)
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self) { ptr in
			dest.assumingMemoryBound(to:Self.self).initialize(to:ptr.pointee)
			return dest.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the signed integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension Int:RAW_convertible_fixed, RAW_comparable_fixed {
	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
		let lhs = Self(RAW_decode:lhs_data)!
		let rhs = Self(RAW_decode:rhs_data)!
		if lhs < rhs {
			return -1
		} else if lhs > rhs {
			return 1
		} else {
			return 0
		}
	}

	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.loadUnaligned(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}


struct My32BitUIntBE:RAW_staticbuff {
	typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)

	var RAW_staticbuff:RAW_staticbuff_storetype

	init(RAW_staticbuff ptr:UnsafeRawPointer) {
		self.RAW_staticbuff = ptr.load(as:RAW_staticbuff_storetype.self)
	}

	static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
		let lhs = UInt32(bigEndian:lhs_data.load(as:UInt32.self))
		let rhs = UInt32(bigEndian:rhs_data.load(as:UInt32.self))
		if lhs < rhs {
			return -1
		} else if lhs > rhs {
			return 1
		} else {
			return 0
		}
	}
}