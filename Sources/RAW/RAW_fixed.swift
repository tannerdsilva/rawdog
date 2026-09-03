/// a protocol for types whose in-memory size is known at compile time.
/// the size of a conforming instance is expressed through the `RAW_fixed_type`
/// associated type rather than a runtime property, which lets ``RAW_staticbuff``,
/// the encoding layer, and consumers reason about memory layout statically.
public protocol RAW_fixed {
	/// the type that expresses the size of this type.
	/// - the size of this type is determined as `MemoryLayout<RAW_fixed_type>.size`
	/// - note: stride and alignment are NOT considered in any part of the implementations of this protocol.
	/// - note: a RAW_fixed_type is almost always going to be a tuple of some number of bytes, or a tuple of individual types that themselves conform to RAW_fixed.
	associatedtype RAW_fixed_type
}

// MARK: - v21 compatibility
// `RAW_staticbuff_storetype` was the v21 storage typealias name (now `RAW_fixed_type`).
// the deprecated bridge intentionally lives on the `RAW_fixed` base protocol so the old
// name resolves on both `RAW_fixed` and `RAW_staticbuff` conformers (qualified and
// unqualified reference sites) with a rename fix-it. the v21 redeclaration pattern
// (`public typealias RAW_fixed_type = RAW_staticbuff_storetype`) is NOT recoverable —
// the `@RAW_staticbuff` macro generates `RAW_fixed_type` itself, so the line must be
// deleted when migrating.
extension RAW_fixed {
	/// v21-compatible name for `RAW_fixed_type`.
	@available(*, deprecated, renamed:"RAW_fixed_type")
	public typealias RAW_staticbuff_storetype = RAW_fixed_type
}

/// attached extension macro that conforms the annotated type to ``RAW_fixed`` and
/// declares `RAW_fixed_type` as a byte tuple of the given size.
///
/// usage:
/// ```swift
/// @RAW_fixed(bytes: 16)
/// struct Packet {}
/// ```
@attached(extension, conformances:RAW_fixed)
public macro RAW_fixed(bytes:Int) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.BytesMacro")

/// freestanding declaration macro that declares a `RAW_fixed_type` byte tuple of the
/// given size. for use inside a type body that wants to write the conformance itself.
/// a convenient way to express `RAW_fixed_type` typealias' without the need to explicitly write them out.
@freestanding(declaration, names: named(RAW_fixed_type))
public macro RAW_fixed_type(bytes:Int) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.BytesMacro")

/// attached extension macro that conforms the annotated type to ``RAW_fixed`` and
/// declares `RAW_fixed_type` as the concatenation of the fixed types given.
///
/// usage:
/// ```swift
/// @RAW_fixed(concat: Header.self, Payload.self)
/// struct Packet {}
/// ```
@attached(extension, conformances:RAW_fixed)
public macro RAW_fixed(concat:any RAW_fixed.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.ConcatMacro")

/// freestanding declaration macro that declares a `RAW_fixed_type` as the concatenation
/// of the fixed types given. for use inside a type body that wants to write the
/// conformance itself.
@freestanding(declaration, names: named(RAW_fixed_type))
public macro RAW_fixed_type(concat:any RAW_fixed.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.ConcatMacro")
