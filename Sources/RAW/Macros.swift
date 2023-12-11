import RAW_macros

// defines a type as a static buffer type. 
// when a type is a static buffer type, it is a fixed size type that can be represented as a raw buffer of bytes. 
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, RAW_comparable, names:arbitrary)
public macro StaticBufferType(_:size_t) = #externalMacro(module: "RAW_macros", type: "FixedSizeBufferTypeMacro")

// defines a type of static buffer that is a concatenation of other static buffer types. these types are encoded and compared sequentially.
@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, RAW_comparable, names:arbitrary)
public macro ConcatBufferType(_ types:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"ConcatBufferTypeMacro")