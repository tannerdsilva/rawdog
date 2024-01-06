import RAW_macros

// defines a type as a static buffer type.
// when a type is a static buffer type, it is a fixed size type that can be represented as a raw buffer of bytes.
// the static buffer (tuple) type can be created using either signed or unsigned bytes. while this does not affect the actual behavior of the type, having the ability to specify the signedness of the type allows for better interoperability with other languages, such as C.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, names:arbitrary)
public macro RAW_staticbuff(_:size_t, isUnsigned:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro")

// defines a type of static buffer that is a concatenation of other static buffer types. these types are encoded and compared sequentially.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, RAW_comparable, names:arbitrary)
public macro ConcatBufferType(_ types:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"ConcatBufferTypeMacro")