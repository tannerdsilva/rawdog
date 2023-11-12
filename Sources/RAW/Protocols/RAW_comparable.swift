import func CRAW.memcmp;

// /// the protocol that enables comparison of programming objects from raw memory representations.
public protocol RAW_comparable {
	/// the static comparable function for this type.
	static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32
}

extension RAW_comparable where Self:Comparable, Self:Equatable, Self:RAW_decodable {
	/// default implementation that compares the raw representation of the type.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		let lhsInitialized = Self(RAW_size:lhs.RAW_size, RAW_data:lhs.RAW_data)!
		let rhsInitialized = Self(RAW_size:rhs.RAW_size, RAW_data:rhs.RAW_data)!
		switch lhsInitialized == rhsInitialized {
			case true:
				return 0
			default:
				if (lhsInitialized < rhsInitialized) {
					return -1
				} else {
					return 1
				}
		}
	}
}