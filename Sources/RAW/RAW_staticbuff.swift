/// a protocol for types backed by statically sized, fixed-layout storage.
/// `RAW_staticbuff` composes ``RAW_fixed``, ``RAW_comparable_fixed``, and `Sendable`,
/// and is the primary conformance that the `@RAW_staticbuff` macros attach to a type.
/// conforming types can be initialized from a forward-seeking pointer, compared by raw
/// byte representation, and (with the access conveniences) read and written in place.
public protocol RAW_staticbuff:RAW_fixed, RAW_comparable_fixed, Sendable {}

// MARK: - Seeking initializer
extension RAW_staticbuff {
	/// initialize from a forward-seeking pointer. the pointer is advanced by the size of the type after initialization.
	public init(RAW_staticbuff_seeking ptr:inout UnsafeRawPointer) {
		defer {
			ptr = ptr.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
		self = ptr.load(as:Self.self)
	}
}

// MARK: - Bitwise NOT operator
extension RAW_staticbuff where Self:RAW_accessible_mutable {
	/// bitwise complement of the raw byte representation of the value.
	public static prefix func ~ (value:Self) -> Self {
		return value.RAW_access_immutable(UnsafeRawBufferPointer.self) { valueBuf in
			var result = value
			result.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { resultBuf in
				for i in 0..<resultBuf.count {
					resultBuf[i] = ~valueBuf[i]
				}
			}
			return result
		}
	}
}

// MARK: - v21 compatibility
// preserved, deprecated, so that v21 source keeps compiling unchanged:
// - `RAW_staticbuff_storetype` was the v21 storage typealias name (now `RAW_fixed_type`).
//   the deprecated bridge lives on the `RAW_fixed` base protocol (see RAW_fixed.swift)
//   so it covers both `RAW_fixed` and `RAW_staticbuff` conformers.
// - `RAW_access_staticbuff` / `RAW_access_staticbuff_mutating` were the v21 raw-pointer
//   access helpers (now `RAW_access_immutable` / `RAW_access_mutable` over buffers).

extension RAW_staticbuff where Self:RAW_accessible_immutable {
	/// v21-compatible raw-pointer access alias for `RAW_access_immutable(UnsafeRawBufferPointer.self, _:)`.
	@available(*, deprecated, message:"use RAW_access_immutable(UnsafeRawBufferPointer.self, _:) instead")
	public borrowing func RAW_access_staticbuff<R, E>(_ body:(UnsafeRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeRawBufferPointer.self) { (buff:UnsafeRawBufferPointer) throws(E) -> R in
			return try body(buff.baseAddress!)
		}
	}
}

extension RAW_staticbuff where Self:RAW_accessible_mutable {
	/// v21-compatible raw-pointer access alias for `RAW_access_mutable(UnsafeMutableRawBufferPointer.self, _:)`.
	@available(*, deprecated, message:"use RAW_access_mutable(UnsafeMutableRawBufferPointer.self, _:) instead")
	public mutating func RAW_access_staticbuff_mutating<R, E>(_ body:(UnsafeMutableRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { (buff:UnsafeMutableRawBufferPointer) throws(E) -> R in
			return try body(buff.baseAddress!)
		}
	}
}

/// the primary macro of the package. attached extension + member macro that conforms an
/// annotated struct to ``RAW_staticbuff`` (and through it ``RAW_fixed``,
/// ``RAW_comparable_fixed``, ``RAW_accessible``, ``RAW_decodable``, ``RAW_encodable``,
/// and ``RAW_comparable``), lays out its storage as a byte tuple of the given size, and
/// generates the storage accessors.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(bytes: 16)
/// struct Packet: RAW_staticbuff {}
/// ```
@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable, RAW_comparable_fixed)
public macro RAW_staticbuff(bytes:Int) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro.BytesMacro")

/// attached extension + member macro that conforms an annotated struct to
/// ``RAW_staticbuff`` and lays out its storage as the concatenation of the staticbuff
/// types given. the composite type's size is the sum of its parts' sizes.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(concat: Header.self, Payload.self)
/// struct Packet: RAW_staticbuff {}
/// ```
@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable, RAW_comparable_fixed)
public macro RAW_staticbuff(concat:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro.ConcatMacro")

/// freestanding expression macro that initializes a ``RAW_staticbuff``-backed value
/// from a decoded raw buffer. emits the length validation and storage copy performed by
/// the macro-generated `init?(RAW_decode:)` bodies.
@freestanding(expression)
public macro RAW_staticbuff_init<S:RAW_staticbuff>(_:S.Type, RAW_decode:UnsafeRawBufferPointer, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_protocol.InitMacro")

/// freestanding expression macro that performs immutable raw access to the storage
/// referenced by a key path, calling a body closure with an `UnsafeRawBufferPointer`.
@freestanding(expression)
public macro RAW_staticbuff_access<S:RAW_staticbuff, E:Swift.Error, R>(_ :S, storage:KeyPath<S, S.RAW_fixed_type>, bodyReturnType:R.Type, bodyThrowsType:E.Type, body:(UnsafeRawBufferPointer) throws(E) -> R) -> R = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_access_decl")

/// freestanding expression macro that performs mutable raw access to the storage
/// referenced by a key path, calling a body closure with an
/// `UnsafeMutableRawBufferPointer`.
@freestanding(expression)
public macro RAW_staticbuff_access_mutating<S:RAW_staticbuff, E:Swift.Error, R>(_ :S, storage:KeyPath<S, S.RAW_fixed_type>, bodyReturnType:R.Type, bodyThrowsType:E.Type, body:(UnsafeMutableRawBufferPointer) throws(E) -> R) -> R = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_access_mutating_decl")

/// freestanding expression macro that writes the size of a ``RAW_fixed`` type into an
/// `inout Int` argument, matching the ``RAW_encodable/RAW_encode(count:)``
/// requirement.
@freestanding(expression)
public macro RAW_staticbuff_encode_count<S:RAW_fixed>(RAW_fixed:S.Type) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_encode_count_decl")

/// freestanding expression macro that encodes the raw storage of a
/// ``RAW_staticbuff``-backed value to a destination pointer, returning the advanced
/// pointer. matches the ``RAW_encodable/RAW_encode(_:destination:)`` requirement.
@freestanding(expression)
public macro RAW_accessible_encode<S:RAW_staticbuff>(_ :S, destination:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_encode_decl")
