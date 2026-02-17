// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

public protocol RAW_accessible_immutable:RAW_encodable {
	/// allows for non-mutating access to the raw representation of the instance through an raw buffer pointer.
	borrowing func RAW_access_immutable<R, E>(as:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error

	/// allows for non-mutating access to the raw representation of the instance through a typed buffer pointer.
	borrowing func RAW_access_immutable<R, E>(as:UnsafeBufferPointer<UInt8>.Type, _ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

public protocol RAW_accessible_mutable:RAW_encodable {
	/// allows for mutating access to the raw representation of the instance through an raw buffer pointer.
	mutating func RAW_access_mutable<R, E>(as:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error

	/// allows for mutating access to the raw representation of the instance through a typed buffer pointer.
	mutating func RAW_access_mutable<R, E>(as:UnsafeMutableBufferPointer<UInt8>.Type, _ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

// MARK: convenience functions 
extension RAW_accessible_immutable {
	public borrowing func RAW_access_immutable<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(as:UnsafeBufferPointer<UInt8>.self, body)
	}
}
extension RAW_accessible_mutable {
	public mutating func RAW_access_mutable<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(as:UnsafeMutableBufferPointer<UInt8>.self, body)
	}
}

// MARK: legacy support
extension RAW_accessible_immutable {
	@available(*, deprecated, renamed:"RAW_access_immutable(as:_:)")
	public borrowing func RAW_access<R, E>(as:UnsafeBufferPointer<UInt8>.Type, _ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(as:UnsafeBufferPointer<UInt8>.self, body)
	}
}
extension RAW_accessible_mutable {
	@available(*, deprecated, renamed:"RAW_access_mutable(as:_:)")
	public mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R {
		return try RAW_access_mutable(as:UnsafeMutableBufferPointer<UInt8>.self, body)
	}
}

public protocol RAW_accessible:RAW_encodable {
	/// allows for non-mutating access to the raw representation of the instance.
	borrowing func RAW_access<R, E>(as:UnsafeBufferPointer<UInt8>.Type, _ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
	/// allows for mutating access to the raw representation of the instance.
	mutating func RAW_access_mutating<R, E>(as:UnsafeMutableBufferPointer<UInt8>.Type, _ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

extension RAW_accessible {
	@available(*, deprecated, renamed:"RAW_access_immutable(as:_:)")
	public borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access(as:UnsafeBufferPointer<UInt8>.self, body)
	}
	@available(*, deprecated, renamed:"RAW_access_mutable(as:_:)")
	/// allows for mutating access to the raw representation of the instance.
	public mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutating(as:UnsafeMutableBufferPointer<UInt8>.self, body)
	}
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
