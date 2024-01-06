import func CRAW.memcmp;

// /// the protocol that enables comparison and equality checks of programming objects from raw memory representations.
public protocol RAW_comparable:RAW_convertible {
	/// the static comparable function for this type.
	/// - returns: an integer value representing the comparison result. the result shall be 0 if the values are equal, else, a negative value if the left value is less than the right value, or a positive value if the left value is greater than the right value.
	static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_size:size_t, rhs_data:UnsafeRawPointer, rhs_size:size_t) -> Int32
}

extension RAW_comparable {

	/// compare two RAW_comparable types in memory, using the RAW_compare function. this typically requires a temporary byte buffer to be allocated in order for the comparison to be performed.
	static func RAW_compare(lhs:Self, rhs:Self) -> Int32 {
		let lhsArray = [UInt8](RAW_encodable:lhs)
		let rhsArray = [UInt8](RAW_encodable:rhs)
		let lhsSize = lhsArray.count
		let rhsSize = rhsArray.count
		return RAW_compare(lhs_data:lhsArray, lhs_size:lhsSize, rhs_data:rhsArray, rhs_size:rhsSize)
	}
}