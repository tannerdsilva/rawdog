import func CRAW.memcmp;

// /// the protocol that enables comparison of programming objects from raw memory representations.
public protocol RAW_comparable {
	/// the static comparable function for this type.
	static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32
}