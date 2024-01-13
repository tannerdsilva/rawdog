// import struct CRAW.size_t;
// import func CRAW.memcpy;
// import func CRAW.memcmp;

// // extend the unsigned 64 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
// extension UInt64:RAW_convertible_fixed, RAW_comparable_fixed {
// 	public init?(RAW_decode:UnsafeRawPointer) {
// 		self.init(bigEndian:RAW_decode.loadUnaligned(as:RAW_fixed_type.self))
// 	}

// 	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		return withUnsafePointer(to:self.bigEndian) { ptr in
// 			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
// 		}
// 	}

// 	public typealias RAW_fixed_type = Self

// 	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
// 		let lhs = Self(RAW_decode:lhs_data)!
// 		let rhs = Self(RAW_decode:rhs_data)!
// 		if lhs < rhs {
// 			return -1
// 		} else if lhs > rhs {
// 			return 1
// 		} else {
// 			return 0
// 		}
// 	}
// }

// // extend the unsigned 32 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
// extension UInt32:RAW_convertible_fixed, RAW_comparable_fixed {
// 	public init?(RAW_decode:UnsafeRawPointer) {
// 		self.init(bigEndian:RAW_decode.loadUnaligned(as:RAW_fixed_type.self))
// 	}

// 	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		return withUnsafePointer(to:self.bigEndian) { ptr in
// 			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
// 		}
// 	}

// 	public typealias RAW_fixed_type = Self

// 	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
// 		let lhs = Self(RAW_decode:lhs_data)!
// 		let rhs = Self(RAW_decode:rhs_data)!
// 		if lhs < rhs {
// 			return -1
// 		} else if lhs > rhs {
// 			return 1
// 		} else {
// 			return 0
// 		}
// 	}
// }

// // extend the unsigned 16 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
// extension UInt16:RAW_convertible_fixed, RAW_comparable_fixed {
// 	public init?(RAW_decode:UnsafeRawPointer) {
// 		self.init(bigEndian:RAW_decode.loadUnaligned(as:RAW_fixed_type.self))
// 	}

// 	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		return withUnsafePointer(to:self.bigEndian) { ptr in
// 			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
// 		}
// 	}

// 	public typealias RAW_fixed_type = Self

// 	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
// 		let lhs = Self(RAW_decode:lhs_data)!
// 		let rhs = Self(RAW_decode:rhs_data)!
// 		if lhs < rhs {
// 			return -1
// 		} else if lhs > rhs {
// 			return 1
// 		} else {
// 			return 0
// 		}
// 	}
// }

// // extend the unsigned 8 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
// extension UInt8:RAW_convertible_fixed, RAW_comparable_fixed {
// 	public init?(RAW_decode:UnsafeRawPointer) {
// 		self = RAW_decode.load(as:RAW_fixed_type.self)
// 	}

// 	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		return withUnsafePointer(to:self) { ptr in
// 			dest.assumingMemoryBound(to:RAW_fixed_type.self).initialize(from:ptr, count:1)
// 			return dest.advanced(by:MemoryLayout<RAW_fixed_type>.size)
// 		}
// 	}

// 	public typealias RAW_fixed_type = Self

// 	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
// 		let lhs = Self(RAW_decode:lhs_data)!
// 		let rhs = Self(RAW_decode:rhs_data)!
// 		if lhs < rhs {
// 			return -1
// 		} else if lhs > rhs {
// 			return 1
// 		} else {
// 			return 0
// 		}
// 	}
// }

// // extend the unsigned integer to conform to the raw static buffer protocol, as it is a fixed size type.
// extension UInt:RAW_convertible_fixed, RAW_comparable_fixed {
// 	public init?(RAW_decode:UnsafeRawPointer) {
// 		self.init(bigEndian:RAW_decode.loadUnaligned(as:RAW_fixed_type.self))
// 	}

// 	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		return withUnsafePointer(to:self.bigEndian) { ptr in
// 			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
// 		}
// 	}

// 	public typealias RAW_fixed_type = Self

// 	public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
// 		let lhs = Self(RAW_decode:lhs_data)!
// 		let rhs = Self(RAW_decode:rhs_data)!
// 		if lhs < rhs {
// 			return -1
// 		} else if lhs > rhs {
// 			return 1
// 		} else {
// 			return 0
// 		}
// 	}
// }