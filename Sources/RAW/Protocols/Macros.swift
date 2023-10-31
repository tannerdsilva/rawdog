import RAW_macros

@attached(member, names:named(fixedBuffer), named(init(RAW_data:)), named(init(_:)), named(asRAW_val))
@attached(extension, conformances:RAW_staticbuff, Collection, ExpressibleByArrayLiteral, names:named(RAW_staticbuff_storetype), named(init(arrayLiteral:)))
// @attached(peer)
// @attached(memberAttribute)
// @attached(accessor)
public macro StaticBufferType(_:UInt16) = #externalMacro(module: "RAW_macros", type: "FixedSizeBufferTypeMacro")