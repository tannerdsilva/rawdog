// LICENSE MIT
// copyright (c) tanner silva 2025. all rights reserved.

import Darwin

/// a type that can be compared with another instance of the same type using a fixed-size comparison.
public protocol RAW_comparable_fixed:RAW_comparable, RAW_fixed {
	/// the theoretical maximum value of this type.
	static func RAW_comparable_fixed_theoretical_max() -> Self
	/// the theoretical minimum value of this type.
	static func RAW_comparable_fixed_theoretical_min() -> Self
	/// compare two instances of the same type using their raw pointer representations.
	static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32
}

/// default implementation for comparable fixed on raw staticbuff types.
extension RAW_comparable_fixed where Self:RAW_staticbuff {
	public static func RAW_comparable_fixed_theoretical_max() -> Self {
		return withUnsafeTemporaryAllocation(byteCount:MemoryLayout<RAW_fixed_type>.size, alignment:MemoryLayout<Self>.alignment) { buffer in
			let bytePtr = buffer.baseAddress!.assumingMemoryBound(to:UInt8.self)
			for i in 0..<buffer.count {
				bytePtr[i] = 0xFF
			}
			return buffer.baseAddress!.load(as:Self.self)
		}
	}
	public static func RAW_comparable_fixed_theoretical_min() -> Self {
		return withUnsafeTemporaryAllocation(byteCount:MemoryLayout<RAW_fixed_type>.size, alignment:MemoryLayout<Self>.alignment) { buffer in
			let bytePtr = buffer.baseAddress!.assumingMemoryBound(to:UInt8.self)
			for i in 0..<buffer.count {
				bytePtr[i] = 0
			}
			return buffer.baseAddress!.load(as:Self.self)
		}
	}
	/// lexicographic comparison of the raw byte representation of two instances.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		return memcmp(lhs_data, rhs_data, MemoryLayout<RAW_fixed_type>.size)
	}
}

extension RAW_comparable_fixed {
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:Int, rhs_data:UnsafeRawPointer, rhs_count:Int) -> Int32 {
		#if DEBUG
		assert(lhs_count == MemoryLayout<RAW_fixed_type>.size, "lhs_count: \(lhs_count) != MemoryLayout<RAW_fixed_type>.size: \(MemoryLayout<RAW_fixed_type>.size)")
		assert(rhs_count == MemoryLayout<RAW_fixed_type>.size, "rhs_count: \(rhs_count) != MemoryLayout<RAW_fixed_type>.size: \(MemoryLayout<RAW_fixed_type>.size)")
		#endif
		return RAW_compare(lhs_data:lhs_data, rhs_data:rhs_data)
	}
}
