// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

// MARK: decode
/// a protocol for types that can initialize from raw durable storage.
/// - NOTE: the length of the buffer must be exactly the length that will be consumed during the initialization. if the length of the buffer is not correct, the initializer *must* return nil. it is expected and REQUIRED that the initializer returns nil if the buffer is not the exact correct length. it is implied that when calling this initializer, the entirety of the buffer can be considered "consumed" if the initializer returns a non-nil value, and that the buffer is not consumed if the initializer returns nil.
public protocol RAW_decodable {
	/// v22 raw byte buffer decode.
	init?(RAW_decode _:UnsafeRawBufferPointer)
}

extension RAW_decodable {
	/// v21-compatible pointer + count decode: forwards to ``RAW_decodable/init(RAW_decode:)`` with
	/// an `UnsafeRawBufferPointer` over the given memory. kept as a deprecated
	/// convenience so v21 call sites keep compiling.
	@available(*, deprecated, message:"use init?(RAW_decode:) with an UnsafeRawBufferPointer")
	public init?(RAW_decode ptr:UnsafeRawPointer, count:Int) {
		self.init(RAW_decode: UnsafeRawBufferPointer(start: ptr, count: count))
	}
}

/// freestanding declaration macro that generates the `init?(RAW_decode:)` signature
/// required by ``RAW_decodable`` for a ``RAW_staticbuff``-backed type.
@freestanding(declaration, names: named(init(RAW_decode:)))
public macro RAW_decode_decl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_decodable_protocol.DecodeMacro")

/// attached body macro that fills in an `init?(RAW_decode:)` body for a
/// ``RAW_staticbuff``-backed type: it validates the buffer length against the fixed
/// type size and copies the raw bytes into the referenced storage.
@attached(body)
public macro RAW_decode_impl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_decodable_protocol.DecodeMacro")

// MARK: encode
/// a protocol for types that can encode themselves to raw durable storage.
public protocol RAW_encodable {
	/// encodes the size of the given instance to a Int inout parameter.
	borrowing func RAW_encode(count:inout Int)

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the exact number of bytes reported by ``RAW_encode(count:)``.
	@discardableResult borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, destination:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
}

/// freestanding declaration macro that generates the
/// `RAW_encode(_:destination:)` signature required by ``RAW_encodable`` for a
/// ``RAW_staticbuff``-backed type.
@freestanding(declaration, names:named(RAW_encode(_:dest:)))
public macro RAW_encode_decl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_encodable_protocol.DataMacro")

/// attached body macro that fills in an `RAW_encode(_:destination:)` body for a
/// ``RAW_staticbuff``-backed type: it copies the raw bytes to the destination pointer
/// and returns the advanced pointer.
@attached(body)
public macro RAW_encode_impl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_encodable_protocol.DataMacro")

/// attached body macro that fills in a `RAW_encode(count:inout Int)` body for a
/// ``RAW_fixed`` type, writing the fixed size of the type.
@attached(body)
public macro RAW_encode_count_impl<S:RAW_fixed>(RAW_fixed:S.Type) = #externalMacro(module:"RAW_macros", type:"RAW_encodable_count_fixed_macro")

// MARK: string types

/// attached member + extension macro that turns an annotated struct into a unicode
/// string type: it attaches ``RAW_encoded_unicode`` conformance and generates the
/// decode, encode, access, compare, and iteration machinery over the given integer
/// backing type.
@attached(member, names: named(RAW_convertible_unicode_encoding), named(RAW_integer_encoding_impl), named(makeIterator()), named(init(RAW_decode:)), named(init(_:)), named(RAW_access_immutable(_:_:)), named(RAW_access_mutable(_:_:)), named(RAW_encode(count:)), named(RAW_encode(_:destination:)))
@attached(extension, conformances: RAW_encoded_unicode)
public macro RAW_convertible_string_type<U:UnicodeCodec>(backing: any RAW_encoded_fixedwidthinteger.Type) = #externalMacro(module:"RAW_macros", type:"RAW_convertible_string_type_macro")

extension RAW_encodable {
	/// byte-typed encode: re-exposes the raw-pointer form through an
	/// `UnsafeMutablePointer<UInt8>` destination.
	@discardableResult public borrowing func RAW_encode(_:UnsafeMutablePointer<UInt8>.Type, destination dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_encode(UnsafeMutableRawPointer.self, destination:dest).assumingMemoryBound(to:UInt8.self)
	}
}
extension RAW_encodable {
	/// untyped byte encode: defaults the destination to `UnsafeMutablePointer<UInt8>`.
	@discardableResult public borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_encode(UnsafeMutablePointer<UInt8>.self, destination:dest)
	}
}
