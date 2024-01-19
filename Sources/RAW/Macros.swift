import RAW_macros

/// defines a type as a static buffer type. 
/// when a type is a static buffer type, it is a fixed size with a "literally expressed" representation in memory. usually, the only way to ensure this is the case in Swift is to write everything as byte tuples (UInt8, UInt8...). thankfully, this macro provides a convenient way to write structures in this way.
/// - arguments:
/// 	- size_t: the byte count of the static buffer type. NOTE: this must be an integer literal in base10 format WITHOUT any special characters ('_' or others) in the value syntax
@attached(member, 		names:			named(RAW_staticbuff_storetype), named(init(RAW_staticbuff:)), named(RAW_access_staticbuff_mutating), named(RAW_encode(count:)), named(RAW_encode(dest:)), named(RAW_access_mutating))
@attached(extension,	conformances:	RAW_staticbuff)
public macro RAW_staticbuff(bytes:size_t) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro")

@attached(member, 		names:			named(RAW_staticbuff_storetype), named(init(RAW_staticbuff:)), named(RAW_access_staticbuff_mutating), named(RAW_encode(count:)), named(RAW_encode(dest:)), named(RAW_access_mutating))
@attached(extension,	conformances:	RAW_staticbuff)
public macro RAW_staticbuff(concat:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro")

// defines a type of static buffer that is a concatenation of other static buffer types. these types are encoded and compared sequentially.
@attached(member, 		names:			named(RAW_staticbuff_storetype))
@attached(extension,	conformances:	RAW_comparable,
										RAW_comparable_fixed,
										RAW_accessible,
										RAW_decodable,
										RAW_encodable,
										RAW_staticbuff,
										RAW_fixed,
										RAW_convertible_fixed,
						names:			named(init(RAW_staticbuff:)),
										named(init(RAW_decode:count:)),
										named(init(RAW_decode:)),
										named(RAW_access_staticbuff_mutating),
										named(RAW_access_mutating),
										named(RAW_encode(dest:)),
										named(RAW_encode(count:)),
										named(RAW_fixed_type),
										named(RAW_compare(lhs_data:lhs_count:rhs_data:rhs_count:)),
										named(RAW_compare(lhs_data:rhs_data:)))
public macro RAW_staticbuff_concat_type(_ types:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_concat_type_macro")

/// automatically implements RAW_staticbuff on any FixedWidthInteger type, allowing the macro user to specify either big or little endian encoding.
/// - behavior is undefined if the specified bits is not the same as the size of the specified FixedWidthInteger type.
/// - implements ``RAW_staticbuff`` on the type unconditionally, and does not allow the user to override the comparison behavior.
@attached(member, 		names:			named(RAW_staticbuff_storetype), named(init(RAW_staticbuff:)), named(RAW_access_staticbuff_mutating))
@attached(extension,	conformances:	RAW_comparable_fixed, 
						names: 			named(RAW_compare(lhs_data:rhs_data:)))
@attached(extension,	conformances:	RAW_comparable_fixed, 
						names:			named(RAW_compare(lhs_data:lhs_count:rhs_data:rhs_count:)))
@attached(extension,	conformances:	RAW_accessible,
						names:			named(RAW_access_mutating))
@attached(extension,	conformances:	RAW_decodable,
										RAW_encodable,
										RAW_convertible_fixed,
						names:			named(init(RAW_decode:count:)),
										named(RAW_encode(dest:)),
										named(RAW_encode(count:)),
										named(init(RAW_decode:)))
@attached(extension,	conformances:	RAW_staticbuff,
										RAW_fixed,
										RAW_encoded_fixedwidthinteger)
@attached(extension,	conformances:	RAW_native,
						names:			named(init(RAW_native:)),
										named(RAW_native))
@attached(extension,	conformances:	ExpressibleByIntegerLiteral,
						names:			named(init(integerLiteral:)))
public macro RAW_staticbuff_fixedwidthinteger_type<T:FixedWidthInteger>(bits:size_t, bigEndian:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_fixedwidthinteger_type_macro")

@attached(extension,	conformances:	RAW_encoded_binaryfloatingpoint)
@attached(extension,	conformances:	RAW_comparable_fixed,
										RAW_comparable,
						names:			named(RAW_compare(lhs_data:rhs_data:)),
										named(RAW_compare(lhs_data:lhs_count:rhs_data:rhs_count:)))
@attached(extension,	conformances:	RAW_native,
										ExpressibleByFloatLiteral,
										ExpressibleByIntegerLiteral,
						names:			named(init(RAW_native:)),
										named(RAW_native),
										named(init(floatLiteral:)),
										named(init(integerLiteral:)))
public macro RAW_staticbuff_binaryfloatingpoint_type<T:BinaryFloatingPoint>() = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_floatingpoint_type_macro")

@attached(member, names:arbitrary)
public macro RAW_convertible_string_type<S:Unicode.Encoding>() = #externalMacro(module:"RAW_macros", type:"RAW_convertible_string_type_macro")
