import RAW_macros

@attached(member, names:named(fixedBuffer), named(init(RAW_data:)), named(asRAW_val))
@attached(extension, conformances:RAW_staticbuff, names:named(RAW_staticbuff_storetype), named(init(RAW_data:)), named(asRAW_val(_:)))
// @attached(peer)
// @attached(memberAttribute)
// @attached(accessor)
public macro FixedBuffer(_:UInt16) = #externalMacro(module: "RAW_macros", type: "FixedBuffer")

@freestanding(declaration)
// @attached(peer)
// @attached(member)
public macro FixedSizeBufferDeclareMacro(_:UInt16) = #externalMacro(module: "RAW_macros", type: "FixedSizeBufferTypeMacro")