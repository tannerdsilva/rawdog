// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

/// the protocol that enables comparison and equality checks of programming objects from raw memory representations.
public protocol RAW_comparable {
	/// the static comparable function for this type.
	/// - returns: an integer value representing the comparison result. the result shall be 0 if the values are equal, else, a negative value if the left value is less than the right value, or a positive value if the left value is greater than the right value.
	static func RAW_compare(_:UnsafeRawBufferPointer, _:UnsafeRawBufferPointer) -> Int32
}

// convenience extension for RAW_comparable types - allows for comparison of unsafe byte buffers without needing to convert them to raw buffer pointers first.
extension RAW_comparable {
	public static func RAW_compare(_ lhs:UnsafeBufferPointer<UInt8>, _ rhs:UnsafeBufferPointer<UInt8>) -> Int32 {
		return RAW_compare(UnsafeRawBufferPointer(lhs), UnsafeRawBufferPointer(rhs))
	}
	public static func RAW_compare(_ lhs:UnsafeMutableBufferPointer<UInt8>, _ rhs:UnsafeMutableBufferPointer<UInt8>) -> Int32 {
		return RAW_compare(UnsafeRawBufferPointer(lhs), UnsafeRawBufferPointer(rhs))
	}
	public static func RAW_compare(_ lhs:UnsafeMutableRawBufferPointer, _ rhs:UnsafeMutableRawBufferPointer) -> Int32 {
		return RAW_compare(UnsafeRawBufferPointer(lhs), UnsafeRawBufferPointer(rhs))
	}
}

// default implementation for all RAW_comparable types - lexicographically sorted data
extension RAW_comparable {
	public static func RAW_compare(_ lhs:UnsafeRawBufferPointer, _ rhs:UnsafeRawBufferPointer) -> Int32 {
		switch (lhs.count, rhs.count) {
			case (0, 0):
				return 0
			case (0, _):
				return -1
			case (_, 0):
				return 1
			default:
				let lhsEndPtr = lhs.baseAddress!.assumingMemoryBound(to:UInt8.self) + lhs.count
				let rhsEndPtr = rhs.baseAddress!.assumingMemoryBound(to:UInt8.self) + rhs.count
				var lhsSeeker = lhs.baseAddress!.assumingMemoryBound(to:UInt8.self)
				var rhsSeeker = rhs.baseAddress!.assumingMemoryBound(to:UInt8.self)
				seekLoop: while lhsSeeker < lhsEndPtr && rhsSeeker < rhsEndPtr {
					defer {
						lhsSeeker += 1
						rhsSeeker += 1
					}
					let byte_a = lhsSeeker.pointee
					let byte_b = rhsSeeker.pointee
					if byte_a != byte_b {
						if byte_a < byte_b {
							return -1
						} else {
							return 1
						}
					} else {
						continue seekLoop;
					}	
				}
				if lhs.count < rhs.count {
					return -1
				} else if lhs.count > rhs.count {
					return 1
				} else {
					return 0
				}
		}
	}
}

// default implementation for RAW_accessible_immutable & Equatable types - equality is determined by the RAW_compare function.
extension RAW_accessible_immutable where Self:Equatable, Self:RAW_comparable {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { lhsBuff in
			rhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { rhsBuff in
				return RAW_compare(lhsBuff, rhsBuff) == 0
			}
		}
	}
}

// default implementation for RAW_accessible_immutable & Comparable types - ordering is determined by the RAW_compare function.
extension RAW_accessible_immutable where Self:Comparable, Self:RAW_comparable {
	public static func < (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { lhsBuff in
			rhs.RAW_access_immutable(UnsafeRawBufferPointer.self) { rhsBuff in
				return RAW_compare(lhsBuff, rhsBuff) < 0
			}
		}
	}
}