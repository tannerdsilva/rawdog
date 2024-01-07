import func CRAW.memcmp;

// /// the protocol that enables comparison and equality checks of programming objects from raw memory representations.
public protocol RAW_comparable:RAW_convertible {
	/// the static comparable function for this type.
	/// - returns: an integer value representing the comparison result. the result shall be 0 if the values are equal, else, a negative value if the left value is less than the right value, or a positive value if the left value is greater than the right value.
	static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32
}

extension RAW_comparable {
	/// compare two RAW_comparable types in memory, using the RAW_compare function. this typically requires a temporary byte buffer to be allocated in order for the comparison to be performed.
	public static func RAW_compare(lhs:Self, rhs:Self) -> Int32 {
		lhs.RAW_access({ buff, size in
			rhs.RAW_access({ buff2, size2 in
				return Self.RAW_compare(lhs_data:buff, lhs_count:size, rhs_data:buff2, rhs_count:size2)
			})
		})
	}
}