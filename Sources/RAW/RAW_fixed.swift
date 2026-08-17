public protocol RAW_fixed {
	/// the type that expresses the size of this type.
	/// - the size of this type is determined as ``MemoryLayout<RAW_fixed_type>.size``
	/// - note: stride and alignment are NOT considered in any part of the implementations of this protocol.
	/// - note: a RAW_fixed_type is almost always going to be a tuple of some number of bytes, or a tuple of individual types that themselves conform to RAW_fixed.
	associatedtype RAW_fixed_type
}

@attached(extension, conformances:RAW_fixed)
public macro RAW_fixed(bytes:Int) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.BytesMacro")

/// a convenient way to express `RAW_fixed_type` typealias' without the need to explicitly write them out.
@freestanding(declaration, names: named(RAW_fixed_type))
public macro RAW_fixed_type(bytes:Int) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.BytesMacro")

@attached(extension, conformances:RAW_fixed)
public macro RAW_fixed(concat:any RAW_fixed.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.ConcatMacro")

@freestanding(declaration, names: named(RAW_fixed_type))
public macro RAW_fixed_type(concat:any RAW_fixed.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_fixed_protocol.ConcatMacro")
