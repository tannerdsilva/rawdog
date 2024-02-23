import RAW_macros

/// defines a type as a static buffer type. 
/// when a type is a static buffer type, it is a fixed size with a "literally expressed" representation in memory. usually, the only way to ensure this is the case in Swift is to write everything as byte tuples (UInt8, UInt8...). thankfully, this macro provides a convenient way to write structures in this way.
/// - arguments:
/// 	- size_t: the byte count of the static buffer type. NOTE: this must be an integer literal in base10 format WITHOUT any special characters ('_' or others) in the value syntax
@attached(member, 		names:			named(RAW_staticbuff_storetype),
										named(RAW_access_staticbuff),
										named(RAW_access),
										named(init(RAW_staticbuff:)),
										named(RAW_encode(count:)),
									 	named(RAW_encode(dest:)),
										named(RAW_compare(lhs_data:lhs_count:rhs_data:rhs_count:)),
										named(RAW_compare(lhs_data:rhs_data:)))
@attached(extension,	conformances:	RAW_staticbuff, Sendable)
public macro RAW_staticbuff(bytes:size_t) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro")

@attached(member, 		names:			named(RAW_staticbuff_storetype),
										named(init(RAW_staticbuff:)),
										named(RAW_access_staticbuff),
										named(RAW_access),
										named(RAW_encode(count:)),
									 	named(RAW_encode(dest:)),
										named(RAW_compare(lhs_data:lhs_count:rhs_data:rhs_count:)),
										named(RAW_compare(lhs_data:rhs_data:)))
@attached(extension,	conformances:	RAW_staticbuff)
public macro RAW_staticbuff(concat:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro")

/// automatically implements RAW_staticbuff on any FixedWidthInteger type, allowing the macro user to specify either big or little endian encoding.
/// - behavior is undefined if the specified bits is not the same as the size of the specified FixedWidthInteger type.
/// - implements ``RAW_staticbuff`` on the type unconditionally, and does not allow the user to override the comparison behavior.
@attached(member,		names:			named(RAW_compare(lhs_data:rhs_data:)),
										named(init(RAW_native:)),
										named(RAW_native),
										named(RAW_native_type))
@attached(extension,	conformances:	RAW_encoded_fixedwidthinteger)
public macro RAW_staticbuff_fixedwidthinteger_type<T:FixedWidthInteger>(bigEndian:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_fixedwidthinteger_type_macro")

@attached(member,		names:			named(RAW_compare(lhs_data:rhs_data:)),
										named(init(RAW_native:)),
										named(RAW_native),
										named(RAW_native_type))
@attached(extension,	conformances:	RAW_encoded_binaryfloatingpoint)
public macro RAW_staticbuff_binaryfloatingpoint_type<T:BinaryFloatingPoint>() = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_floatingpoint_type_macro")

@attached(member,		names:			named(init(_:)),
										named(makeIterator()),
										named(RAW_access),
										named(RAW_integer_encoding_impl),
										named(RAW_convertible_unicode_encoding),
										named(init(RAW_decode:count:)),
										named(RAW_encode(count:)),
										named(RAW_encode(dest:)))
@attached(extension,	conformances:	RAW_encoded_unicode)
public macro RAW_convertible_string_type<S:RAW_encoded_fixedwidthinteger>(_:any UnicodeCodec.Type) = #externalMacro(module:"RAW_macros", type:"RAW_convertible_string_type_macro")
