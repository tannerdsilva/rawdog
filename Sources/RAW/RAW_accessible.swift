// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

/// a protocol for variable-length access to raw data.
public typealias RAW_accessible = RAW_accessible_mutable & RAW_accessible_immutable

// MARK: immutable access
/// protocol for immutable access to raw contiguous data.
/// BOTH `RAW_access` (v21 name) and `RAW_access_immutable(_:_:)` (v22 name) are
/// requirements, each with a default implemented in terms of the other. a conformer
/// implements whichever name it was written against and gets the other for free:
/// v21 hand-written bodies witness `RAW_access`; macro-generated types witness
/// `RAW_access_immutable(_:_:)`. keeping both names as requirements (rather than
/// defaulting one) is what routes generic in-module dispatch through the witness
/// table to the conformer's concrete member instead of recursing into the defaults.
public protocol RAW_accessible_immutable {
	/// v21-compatible typed-throws access to the raw byte representation.
	@available(*, deprecated, message:"use RAW_access_immutable(UnsafeRawBufferPointer.self, _:) instead")
	borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
	/// v22 raw-buffer accessor.
	borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

extension RAW_accessible_immutable {
	/// `RAW_access` default for macro-generated types: forwards through the witness
	/// table to their concrete `RAW_access_immutable(_:_:)` member.
	@available(*, deprecated, message:"use RAW_access_immutable(UnsafeRawBufferPointer.self, _:) instead")
	public borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeRawBufferPointer.self) { (raw:UnsafeRawBufferPointer) throws(E) -> R in
			return try body(UnsafeBufferPointer<UInt8>(start:raw.baseAddress?.assumingMemoryBound(to:UInt8.self), count:raw.count))
		}
	}

	/// `RAW_access_immutable(_:_:)` default for v21 conformers: forwards through the
	/// witness table to their `RAW_access` body.
	public borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access { (buf:UnsafeBufferPointer<UInt8>) throws(E) -> R in
			return try body(UnsafeRawBufferPointer(start:buf.baseAddress, count:buf.count))
		}
	}
}

/// freestanding declaration macro that generates the `RAW_access_immutable(_:_:)`
/// signature required by ``RAW_accessible_immutable`` for a
/// ``RAW_staticbuff``-backed type.
@freestanding(declaration, names: named(RAW_access_immutable(_:_:)))
public macro RAW_access_immutable_decl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_accessible_protocol.ImmutableMacro")

/// attached body macro that fills in an `RAW_access_immutable(_:_:)` body for a
/// ``RAW_staticbuff``-backed type, passing an `UnsafeRawBufferPointer` over the
/// referenced storage to the body closure.
@attached(body)
public macro RAW_access_immutable_impl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_accessible_protocol.ImmutableMacro")

// convenience: byte-typed buffer access over the raw buffer accessor.
extension RAW_accessible_immutable {
	/// byte-typed access over the raw buffer accessor: re-exposes the raw buffer as an
	/// `UnsafeBufferPointer<UInt8>`.
	public borrowing func RAW_access_immutable<R, E>(_:UnsafeBufferPointer<UInt8>.Type, _ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeRawBufferPointer.self) { buff throws(E) -> R in
			return try body(.init(start:buff.baseAddress?.assumingMemoryBound(to:UInt8.self), count:buff.count))
		}
	}
}

// RAW_encodable implementation for all RAW_accessible_immutable types - simply copies the raw bytes to the destination buffer.
extension RAW_accessible_immutable where Self:RAW_encodable {
	/// reports the byte count of the encoded value, via the raw buffer accessor.
	public borrowing func RAW_encode(count:inout Int) {
		RAW_access_immutable { buffer in
			count = buffer.count
		}
	}
	/// copies the raw bytes to the destination pointer and returns the advanced pointer.
	public borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, destination:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		RAW_access_immutable(UnsafeRawBufferPointer.self) { ptr in
			return RAW_memcpy(destination, ptr.baseAddress, ptr.count) + ptr.count
		}
	}
}

extension RAW_accessible_immutable where Self:Hashable {
	/// hashes the raw byte representation of the value.
	public func hash(into hasher:inout Hasher) {
		RAW_access_immutable(UnsafeRawBufferPointer.self) { buff in
			hasher.combine(bytes:buff)
		}
	}
}

// MARK: mutable access
/// protocol for mutable access to raw contiguous data.
/// mirrors `RAW_accessible_immutable`: `RAW_access_mutating` (v21) and
/// `RAW_access_mutable(_:_:)` (v22) are both requirements with mutual defaults.
public protocol RAW_accessible_mutable:RAW_accessible_immutable {
	/// v21-compatible typed-throws mutable access to the raw byte representation.
	@available(*, deprecated, message:"use RAW_access_mutable(UnsafeMutableRawBufferPointer.self, _:) instead")
	mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error
	/// v22 raw-buffer mutable accessor.
	mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

extension RAW_accessible_mutable {
	/// `RAW_access_mutating` default for macro-generated types: forwards through the
	/// witness table to their concrete `RAW_access_mutable(_:_:)` member.
	@available(*, deprecated, message:"use RAW_access_mutable(UnsafeMutableRawBufferPointer.self, _:) instead")
	public mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { (raw:UnsafeMutableRawBufferPointer) throws(E) -> R in
			return try body(UnsafeMutableBufferPointer<UInt8>(start:raw.baseAddress?.assumingMemoryBound(to:UInt8.self), count:raw.count))
		}
	}

	/// `RAW_access_mutable(_:_:)` default for v21 conformers: forwards through the
	/// witness table to their `RAW_access_mutating` body.
	public mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutating { (buf:UnsafeMutableBufferPointer<UInt8>) throws(E) -> R in
			return try body(UnsafeMutableRawBufferPointer(start:buf.baseAddress, count:buf.count))
		}
	}
}

/// freestanding declaration macro that generates the `RAW_access_mutable(_:_:)`
/// signature required by ``RAW_accessible_mutable`` for a
/// ``RAW_staticbuff``-backed type.
@freestanding(declaration, names: named(RAW_access_mutable(_:_:)))
public macro RAW_access_mutable_decl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_accessible_protocol.MutableMacro")

/// attached body macro that fills in an `RAW_access_mutable(_:_:)` body for a
/// ``RAW_staticbuff``-backed type, passing an `UnsafeMutableRawBufferPointer` over
/// the referenced storage to the body closure.
@attached(body)
public macro RAW_access_mutable_impl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_accessible_protocol.MutableMacro")

// convenience: byte-typed buffer access over the raw buffer accessor.
extension RAW_accessible_mutable {
	/// byte-typed mutable access over the raw buffer accessor: re-exposes the raw
	/// buffer as an `UnsafeMutableBufferPointer<UInt8>`.
	public mutating func RAW_access_mutable<R, E>(_:UnsafeMutableBufferPointer<UInt8>.Type, _ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buff throws(E) -> R in
			return try body(.init(start:buff.baseAddress?.assumingMemoryBound(to:UInt8.self), count:buff.count))
		}
	}
}

// MARK: legacy & convenience
// default implementation for all RAW_accessible_immutable types - simply provides `UnsafeBufferPointer<UInt8>` access to the raw bytes of the instance when a type is not specified.
extension RAW_accessible_immutable {
	/// untyped byte access: defaults the buffer type to `UnsafeBufferPointer<UInt8>`.
	public borrowing func RAW_access_immutable<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeBufferPointer<UInt8>.self, body)
	}
}
// default implementation for all RAW_accessible_mutable types - simply provides `UnsafeMutableBufferPointer<UInt8>` access to the raw bytes of the instance when a type is not specified.
extension RAW_accessible_mutable {
	/// untyped mutable byte access: defaults the buffer type to
	/// `UnsafeMutableBufferPointer<UInt8>`.
	public mutating func RAW_access_mutable<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(UnsafeMutableBufferPointer<UInt8>.self, body)
	}
}
