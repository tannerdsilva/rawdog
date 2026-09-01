// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

// MARK: decode
/// a protocol for types that can initialize from raw durable storage.
/// - NOTE: the length of the buffer must be exactly the length that will be consumed during the initialization. if the length of the buffer is not correct, the initializer *must* return nil. it is expected and REQUIRED that the initializer returns nil if the buffer is not the exact correct length. it is implied that when calling this initializer, the entirety of the buffer can be considered "consumed" if the initializer returns a non-nil value, and that the buffer is not consumed if the initializer returns nil.
public protocol RAW_decodable {
	/// v21-compatible pointer + count decode. both this and the buffer form are
	/// requirements with mutual defaults, so generic code dispatches through the
	/// witness table: v21 hand-written conformances witness this form, macro-generated
	/// types witness the buffer form (C `size_t` imports as `Int`).
	@available(*, deprecated, message:"use init?(RAW_decode:) with an UnsafeRawBufferPointer")
	init?(RAW_decode _:UnsafeRawPointer, count:Int)
	/// v22 raw byte buffer decode.
	init?(RAW_decode _:UnsafeRawBufferPointer)
}

extension RAW_decodable {
	/// pointer + count decode default for macro-generated types: forwards through the
	/// witness table to their buffer initializer.
	public init?(RAW_decode ptr:UnsafeRawPointer, count:Int) {
		self.init(RAW_decode: UnsafeRawBufferPointer(start: ptr, count: count))
	}

	/// buffer decode default for v21 conformers: forwards through the witness table to
	/// their pointer + count initializer. a nil base address (empty buffer) fails: no
	/// valid decode can begin from zero bytes.
	public init?(RAW_decode buff:UnsafeRawBufferPointer) {
		guard let base = buff.baseAddress else {
			return nil
		}
		self.init(RAW_decode: base, count: buff.count)
	}
}

@freestanding(declaration, names: named(init(RAW_decode:)))
public macro RAW_decode_decl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_decodable_protocol.DecodeMacro")

@attached(body)
public macro RAW_decode_impl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_decodable_protocol.DecodeMacro")

// MARK: encode
/// a protocol for types that can encode themselves to raw durable storage.
public protocol RAW_encodable {
	/// encodes the size of the given instance to a Int inout parameter.
	borrowing func RAW_encode(count:inout Int)

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the number of bytes returned in ``RAW_byte_count``.
	@discardableResult borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, destination:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
}

@freestanding(declaration, names:named(RAW_encode(_:dest:)))
public macro RAW_encode_decl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_encodable_protocol.DataMacro")

@attached(body)
public macro RAW_encode_impl<S:RAW_staticbuff>(RAW_staticbuff:S.Type, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_encodable_protocol.DataMacro")

@attached(body)
public macro RAW_encode_count_impl<S:RAW_fixed>(RAW_fixed:S.Type) = #externalMacro(module:"RAW_macros", type:"RAW_encodable_count_fixed_macro")

// MARK: string types

@attached(member, names: named(RAW_convertible_unicode_encoding), named(RAW_integer_encoding_impl), named(makeIterator()), named(init(RAW_decode:)), named(init(_:)), named(RAW_access_immutable(_:_:)), named(RAW_access_mutable(_:_:)), named(RAW_encode(count:)), named(RAW_encode(_:destination:)))
@attached(extension, conformances: RAW_encoded_unicode)
public macro RAW_convertible_string_type<U:UnicodeCodec>(backing: any RAW_encoded_fixedwidthinteger.Type) = #externalMacro(module:"RAW_macros", type:"RAW_convertible_string_type_macro")

extension RAW_encodable {
	@discardableResult public borrowing func RAW_encode(_:UnsafeMutablePointer<UInt8>.Type, destination dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_encode(UnsafeMutableRawPointer.self, destination:dest).assumingMemoryBound(to:UInt8.self)
	}
}
extension RAW_encodable {
	@discardableResult public borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_encode(UnsafeMutablePointer<UInt8>.self, destination:dest)
	}
}

