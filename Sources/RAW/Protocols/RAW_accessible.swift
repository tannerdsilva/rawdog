// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
public protocol RAW_accessible:RAW_encodable {
	/// allows for non-mutating access to the raw representation of the instance.
	borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
	/// allows for mutating access to the raw representation of the instance.
	mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

extension RAW_accessible {
	public borrowing func RAW_encode(count:inout Int) {
		RAW_access { buffer in
			count = buffer.count
		}
	}
	public borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_access { buffer in
			_ = RAW_memcpy(dest, buffer.baseAddress!, buffer.count)
			return dest + buffer.count
		}
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
