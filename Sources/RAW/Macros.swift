import RAW_macros

/// defines a type as a static buffer type. 
/// when a type is a static buffer type, it is a fixed size with a presumed "perfectly accurate" representation in memory. usually, the only way to ensure this is the case in Swift is to write everything as byte tuples (UInt8, UInt8...). thankfully, this macro provides a convenient way to write structures in this way.
/// - arguments:
/// 	- size_t: the size of the static buffer type.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, names:arbitrary)
public macro RAW_staticbuff(_:size_t) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro")

// defines a type of static buffer that is a concatenation of other static buffer types. these types are encoded and compared sequentially.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, RAW_comparable, names:arbitrary)
public macro RAW_staticbuff_concat_type(_ types:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_concat_type_macro")

/// automatically implements RAW_staticbuff on any FixedWidthInteger type, allowing the macro user to specify either big or little endian encoding.
/// - behavior is undefined if the specified bits is not the same as the size of the specified FixedWidthInteger type.
/// - implements ``RAW_staticbuff`` on the type unconditionally, and does not allow the user to override the comparison behavior.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_encoded_fixedwidthinteger)
public macro RAW_staticbuff_fixedwidthinteger_type<T:FixedWidthInteger>(bits:size_t, bigEndian:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_fixedwidthinteger_type_macro")

/// declares the initializer that allows a struct expanded with ``@RAW_staticbuff_fixedwidthinteger_type`` to be initialized from a static buffer.
@freestanding(declaration, names:arbitrary)
public macro RAW_staticbuff_fixedwidthinteger_init<R:RAW_staticbuff>(bigEndian:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_fixedwidthinteger_bridge_macro")

@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, names:arbitrary)
public macro RAW_staticbuff_binaryfloatingpoint_type<T:BinaryFloatingPoint>() = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_floatingpoint_type_macro")

@freestanding(declaration, names:arbitrary)
public macro RAW_staticbuff_binaryfloatingpoint_init<T:RAW_staticbuff>() = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_binaryfloatingpoint_init_macro")

@attached(member, names:arbitrary)
@attached(memberAttribute)
public macro RAW_convertible_string_type<S:Unicode.Encoding>() = #externalMacro(module:"RAW_macros", type:"RAW_convertible_string_type_macro")
