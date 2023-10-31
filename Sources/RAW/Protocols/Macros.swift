import RAW_macros

@attached(member, names:arbitrary)
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, names:named(RAW_staticbuff_storetype), named(init(arrayLiteral:)))
// @attached(peer)
// @attached(memberAttribute)
// @attached(accessor)
public macro StaticBufferType(_:UInt16) = #externalMacro(module: "RAW_macros", type: "FixedSizeBufferTypeMacro")