// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import func CRAW.memcmp;

// /// the protocol that enables comparison and equality checks of programming objects from raw memory representations.
public protocol RAW_comparable {
	/// the static comparable function for this type.
	/// - returns: an integer value representing the comparison result. the result shall be 0 if the values are equal, else, a negative value if the left value is less than the right value, or a positive value if the left value is greater than the right value.
	static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32
}

extension RAW_comparable {
	// lexi sort is applied to the data
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
		let result = memcmp(lhs_data, rhs_data, min(lhs_count, rhs_count))
		if result != 0 {
			return result
		}
		return lhs_count < rhs_count ? -1 : (lhs_count > rhs_count ? 1 : 0)
	}
}

extension RAW_accessible where Self:Equatable, Self:RAW_comparable {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access({ lhsBuff in
			rhs.RAW_access({ rhsBuff in
				return RAW_compare(lhs_data:lhsBuff.baseAddress!, lhs_count:lhsBuff.count, rhs_data:rhsBuff.baseAddress!, rhs_count:rhsBuff.count) == 0
			})
		})
	}
}

extension RAW_accessible where Self:Comparable, Self:RAW_comparable {
	public static func < (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access({ lhsBuff in
			rhs.RAW_access({ rhsBuff in
				return RAW_compare(lhs_data:lhsBuff.baseAddress!, lhs_count:lhsBuff.count, rhs_data:rhsBuff.baseAddress!, rhs_count:rhsBuff.count) < 0
			})
		})
	}
}
