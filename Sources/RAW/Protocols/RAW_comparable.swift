import func CRAW.memcmp;

// /// the protocol that enables comparison of programming objects from raw memory representations.
public protocol RAW_comparable {
	/// the static comparable function for this type.
	static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32
}

extension RAW_comparable where Self:Comparable, Self:Equatable, Self:RAW_decodable {
	/// default implementation that compares the raw representation of the type.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		return withUnsafePointer(to:lhs.RAW_size) { lhsSizePtr in
			return withUnsafePointer(to:rhs.RAW_size) { rhsSizePtr in
				if (lhsSizePtr.pointee != rhsSizePtr.pointee) {
					return (lhsSizePtr.pointee < rhsSizePtr.pointee) ? -1 : 1
				} else {
					return withUnsafePointer(to:lhs.RAW_data) { lhsDataPtr in
						withUnsafePointer(to:rhs.RAW_data) { rhsDataPtr in
							return RAW_memcmp(lhsDataPtr, rhsDataPtr, lhsSizePtr.pointee)
						}
					}
				}
			}
		}
	}
}