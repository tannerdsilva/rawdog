import RAW_macros

/// defines a type as a static buffer type.
/// when a type is a static buffer type, it is a fixed size with a presumed "perfectly accurate" representation in memory. usually, the only way to ensure this is the case in Swift is to write everything as byte tuples (UInt8, UInt8...). thankfully, this macro provides a convenient way to write structures in this way.
/// - arguments:
/// 	- size_t: the size of the static buffer type.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, names:arbitrary)
public macro RAW_staticbuff(_:size_t) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro")

// defines a type of static buffer that is a concatenation of other static buffer types. these types are encoded and compared sequentially.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, RAW_comparable, names:arbitrary)
public macro ConcatBufferType(_ types:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"ConcatBufferTypeMacro")

/// automatically implements RAW_staticbuff on any FixedWidthInteger type, allowing the macro user to specify either big or little endian encoding.
/// the type of FixedWidthInteger is extended to provide native bi-directional initialization from the attached type decl.
/// - behavior is undefined if the specified bits is not the same as the size of the FixedWidthInteger type.
/// - implements ``RAW_comparable`` on the type unconditionally.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, RAW_comparable, names:arbitrary)
public macro RAW_staticbuff_fixedwidthinteger_explicit_macro<T:FixedWidthInteger>(bits:size_t, bigEndianEncode:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_fixedwidthinteger_explicit_macro")


@freestanding(expression)
public macro RAW_staticbuff_fixedwidthinteger_macro<T:FixedWidthInteger>(bits:size_t, bigEndianEncode:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_fixedwidthinteger_implicit_macro")
