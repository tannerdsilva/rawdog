import RAW_macros

@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, RAW_comparable, names:arbitrary)
// @attached(peer)
// @attached(memberAttribute)
// @attached(accessor)
public macro StaticBufferType(_:size_t) = #externalMacro(module: "RAW_macros", type: "FixedSizeBufferTypeMacro")

@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, Equatable, Comparable, RAW_comparable, names:arbitrary)
public macro ConcatBufferType(_ types:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"ConcatBufferTypeMacro")

// @freestanding(expression)
// public macro ByteTuple(_:size_t) = #externalMacro(module: "RAW_macros", type: "GenerateByteTuple")