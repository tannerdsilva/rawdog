// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

/// the protocol that enables comparison and equality checks of programming objects from raw memory representations.
///	- notes about extensions and conformances:
///		- every RAW_comparable conforming symbol automatically leverages the "default extension", where memory is sorted lexicographically with memcmp.
///		- every RAW_accessible 
public protocol RAW_comparable {
	/// the static comparable function for this type.
	/// - returns: an integer value representing the comparison result. the result shall be 0 if the values are equal, else, a negative value if the left value is less than the right value, or a positive value if the left value is greater than the right value.
	static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:Int, rhs_data:UnsafeRawPointer, rhs_count:Int) -> Int32
}

// default implementation for all RAW_comparable types - lexicographically sorted data
extension RAW_comparable {
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:Int, rhs_data:UnsafeRawPointer, rhs_count:Int) -> Int32 {
		let result = RAW_memcmp(lhs_data, rhs_data, min(lhs_count, rhs_count))
		guard result == 0 else {
			return lhs_count < rhs_count ? -1 : (lhs_count > rhs_count ? 1 : 0)
		}
		return result
	}
}