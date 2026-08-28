public protocol RAW_staticbuff:RAW_fixed, RAW_comparable_fixed, Sendable {}

// MARK: - Seeking initializer
extension RAW_staticbuff {
	/// initialize from a forward-seeking pointer. the pointer is advanced by the size of the type after initialization.
	public init(RAW_staticbuff_seeking ptr:inout UnsafeRawPointer) {
		defer {
			ptr = ptr.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
		self = ptr.load(as:Self.self)
	}
}

// MARK: - Bitwise NOT operator
extension RAW_staticbuff where Self:RAW_accessible_mutable {
	public static prefix func ~ (value:Self) -> Self {
		return value.RAW_access_immutable(UnsafeRawBufferPointer.self) { valueBuf in
			var result = value
			result.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { resultBuf in
				for i in 0..<resultBuf.count {
					resultBuf[i] = ~valueBuf[i]
				}
			}
			return result
		}
	}
}

@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable, RAW_comparable_fixed)
public macro RAW_staticbuff(bytes:Int) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro.BytesMacro")

@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable, RAW_comparable_fixed)
public macro RAW_staticbuff(concat:any RAW_staticbuff.Type...) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_macro.ConcatMacro")

@freestanding(expression)
public macro RAW_staticbuff_init<S:RAW_staticbuff>(_:S.Type, RAW_decode:UnsafeRawBufferPointer, storage:KeyPath<S, S.RAW_fixed_type>) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_protocol.InitMacro")

@freestanding(expression)
public macro RAW_staticbuff_access<S:RAW_staticbuff, E:Swift.Error, R>(_ :S, storage:KeyPath<S, S.RAW_fixed_type>, bodyReturnType:R.Type, bodyThrowsType:E.Type, body:(UnsafeRawBufferPointer) throws(E) -> R) -> R = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_access_decl")

@freestanding(expression)
public macro RAW_staticbuff_access_mutating<S:RAW_staticbuff, E:Swift.Error, R>(_ :S, storage:KeyPath<S, S.RAW_fixed_type>, bodyReturnType:R.Type, bodyThrowsType:E.Type, body:(UnsafeMutableRawBufferPointer) throws(E) -> R) -> R = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_access_mutating_decl")

@freestanding(expression)
public macro RAW_staticbuff_encode_count<S:RAW_fixed>(RAW_fixed:S.Type) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_encode_count_decl")

@freestanding(expression)
public macro RAW_accessible_encode<S:RAW_staticbuff>(_ :S, destination:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_encode_decl")
