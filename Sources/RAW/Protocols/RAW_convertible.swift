/// convertible (alias) protocol that encapsulates encodable and decodable protocols.
public typealias RAW_convertible = RAW_encodable & RAW_decodable

/// the protocol that enables initialization of programming objects from raw memory.
/// - initializers may return nil if the memory is not valid for the given type.
public protocol RAW_decodable {
	/// required implementation.
	init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?)
}

/// the protocol that enables encoding of programming objects to raw memory.
public protocol RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R
}

// implement default comparison operators for RAW_encodable types that implement RAW_comparable
extension RAW_encodable where Self:RAW_comparable {
	/// default equality implementation based on the byte contents of the ``RAW_val``.
	public static func < (lhs:Self, rhs:Self) -> Bool {
		return lhs.asRAW_val({ lval in
			return rhs.asRAW_val({ rval in
				return RAW_compare(lval, rval) < 0
			})
		})
	}
}
// implement default comparison operators for RAW_encodable types that implement RAW_comparable
extension RAW_encodable where Self:RAW_comparable {
	/// default equality implementation based on the byte contents of the ``RAW_val``.
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.asRAW_val({ lval in
			return rhs.asRAW_val({ rval in
				return RAW_compare(lval, rval) == 0
			})
		})
	}
}
