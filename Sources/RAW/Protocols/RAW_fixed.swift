// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
/// a type that does not require any size arguments because the size is known at compile time via the RAW_fixed_type associated type.
public protocol RAW_fixed {
	/// the type that expresses the size of this type.
	/// - the size of this type is determined as ``MemoryLayout<RAW_fixed_type>.size``
	/// - note: stride and alignment are NOT considered in any part of the implementations of this protocol.
	associatedtype RAW_fixed_type
}

/// a RAW_convertible type that is also RAW_fixed.
public protocol RAW_convertible_fixed:RAW_convertible, RAW_fixed {
	init?(RAW_decode:UnsafeRawPointer)
}

/// extensions that provide the expected implementations for ``RAW_convertible`` based on the knowledge gained from the ``RAW_fixed`` protocol.
extension RAW_convertible_fixed {
	public init?(RAW_decode ptr:UnsafeRawPointer, count:size_t) {
		guard count == MemoryLayout<RAW_fixed_type>.size else {
			return nil
		}
		self.init(RAW_decode:ptr)
	}
}

/// a type that can be compared with another instance of the same type.
public protocol RAW_comparable_fixed:RAW_comparable, RAW_fixed {
	/// the theoretical maximum value of this type.
	static func RAW_comparable_fixed_theoretical_max() -> Self
	/// the theoretical minimum value of this type.
	static func RAW_comparable_fixed_theoretical_min() -> Self
	/// compare two instances of the same type.
	static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32
}

extension RAW_comparable_fixed where Self:RAW_staticbuff {
	public static func RAW_comparable_fixed_theoretical_max() -> Self {
		return ~Self(RAW_staticbuff:Self.RAW_staticbuff_zeroed())
	}
	public static func RAW_comparable_fixed_theoretical_min() -> Self {
		return Self(RAW_staticbuff:Self.RAW_staticbuff_zeroed())
	}
}

extension RAW_comparable_fixed {
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
		#if DEBUG
		assert(lhs_count == MemoryLayout<RAW_fixed_type>.size, "lhs_count: \(lhs_count) != MemoryLayout<RAW_fixed_type>.size: \(MemoryLayout<RAW_fixed_type>.size)")
		assert(rhs_count == MemoryLayout<RAW_fixed_type>.size, "rhs_count: \(rhs_count) != MemoryLayout<RAW_fixed_type>.size: \(MemoryLayout<RAW_fixed_type>.size)")
		#endif
		return RAW_compare(lhs_data:lhs_data, rhs_data:rhs_data)
	}

	public static func RAW_compare(lhs_data_seeking:inout UnsafeRawPointer, rhs_data_seeking:inout UnsafeRawPointer) -> Int32 {
		defer {
			lhs_data_seeking = lhs_data_seeking.advanced(by:MemoryLayout<RAW_fixed_type>.size)
			rhs_data_seeking = rhs_data_seeking.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
		return RAW_compare(lhs_data:lhs_data_seeking, rhs_data:rhs_data_seeking)
	}
}