// import func CRAW.memcpy;

// extension Double:RAW_convertible_fixed, RAW_comparable_fixed {
// 	public init?(RAW_decode:UnsafeRawPointer) {
// 		self.init(bitPattern:RAW_decode.loadUnaligned(as:RAW_fixed_type.self))
// 	}

// 	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		return withUnsafePointer(to:self.bitPattern) { ptr in
// 			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
// 		}
// 	}

// 	public typealias RAW_fixed_type = UInt64

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
// 	}}

// extension Float:RAW_convertible_fixed, RAW_comparable_fixed{
// 	public init?(RAW_decode:UnsafeRawPointer) {
// 		self.init(bitPattern:RAW_decode.loadUnaligned(as:RAW_fixed_type.self))
// 	}

// 	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		return withUnsafePointer(to:self.bitPattern) { ptr in
// 			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
// 		}
// 	}

// 	public typealias RAW_fixed_type = UInt32

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
// 	}}