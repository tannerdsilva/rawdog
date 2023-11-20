import func CRAW.memcmp;

// /// the protocol that enables comparison and equality checks of programming objects from raw memory representations.
public protocol RAW_comparable {
	/// the static comparable function for this type.
	/// - returns: an integer value representing the comparison result. the result shall be 0 if the values are equal, else, a negative value if the left value is less than the right value, or a positive value if the left value is greater than the right value.
	static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32
}