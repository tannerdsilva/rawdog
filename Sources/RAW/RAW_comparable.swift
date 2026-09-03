// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
@_exported import CRAW
import func CRAW.memcmp

/// the protocol that enables comparison and equality checks of programming objects from raw memory representations.
public protocol RAW_comparable {
	/// the static comparable function for this type.
	/// - returns: an integer value representing the comparison result. the result shall be 0 if the values are equal, else, a negative value if the left value is less than the right value, or a positive value if the left value is greater than the right value.
	static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:Int, rhs_data:UnsafeRawPointer, rhs_count:Int) -> Int32
}

extension RAW_comparable {
	// lexi sort is applied to the data
	/// default lexicographic byte comparison: compares the common prefix with `memcmp`
	/// and falls back to length ordering when the prefixes match.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:Int, rhs_data:UnsafeRawPointer, rhs_count:Int) -> Int32 {
		let result = memcmp(lhs_data, rhs_data, min(lhs_count, rhs_count))
		if result != 0 {
			return result
		}
		return lhs_count < rhs_count ? -1 : (lhs_count > rhs_count ? 1 : 0)
	}
}

// Equatable sugar for RAW_accessible_immutable types that are also RAW_comparable
extension RAW_accessible_immutable where Self:Equatable, Self:RAW_comparable {
	/// byte-wise equality through the raw byte representations of both values.
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { lhsBuf in
			rhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { rhsBuf in
				return RAW_compare(lhs_data:lhsBuf.baseAddress!, lhs_count:lhsBuf.count, rhs_data:rhsBuf.baseAddress!, rhs_count:rhsBuf.count) == 0
			}
		}
	}
}

// Comparable sugar for RAW_accessible_immutable types that are also RAW_comparable
extension RAW_accessible_immutable where Self:Comparable, Self:RAW_comparable {
	/// lexicographic byte-wise ordering through the raw byte representations.
	public static func < (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { lhsBuf in
			rhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { rhsBuf in
				return RAW_compare(lhs_data:lhsBuf.baseAddress!, lhs_count:lhsBuf.count, rhs_data:rhsBuf.baseAddress!, rhs_count:rhsBuf.count) < 0
			}
		}
	}
}
