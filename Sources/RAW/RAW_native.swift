// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

/// a protocol that is applied on types that represent an explicit encoding scheme of a native type. these types can include things like
public protocol RAW_native {
	/// the native type that this type represents an encoding of
	associatedtype RAW_native_type
	/// an initializer that takes a value of the native type and returns an instance of this type
	init(RAW_native:RAW_native_type)
	/// a function that returns the value of the native type that this type represents an encoding of
	func RAW_native() -> RAW_native_type
}

/// attached member macro that generates `RAW_native()` and `init(RAW_native:)` for a `RAW_staticbuff` type
/// backed by a `FixedWidthInteger` type, and attaches the `RAW_encoded_fixedwidthinteger` conformance.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(bytes:4)
/// @RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
/// struct MyUInt32:RAW_staticbuff {}
/// ```
@attached(member, names: named(RAW_native()), named(init(RAW_native:)))
@attached(extension, conformances: RAW_encoded_fixedwidthinteger)
public macro RAW_staticbuff_fixedwidthinteger_type<T:FixedWidthInteger>(bigEndian:Bool) = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_fixedwidthinteger_type_macro")

/// attached member macro that generates `RAW_native()` and `init(RAW_native:)` for a `RAW_staticbuff` type
/// backed by a `BinaryFloatingPoint` type, and attaches the `RAW_encoded_binaryfloatingpoint` conformance.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(bytes:4)
/// @RAW_staticbuff_binaryfloatingpoint_type<Float>()
/// struct MyFloat:RAW_staticbuff {}
/// ```
@attached(member, names: named(RAW_native()), named(init(RAW_native:)))
@attached(extension, conformances: RAW_encoded_binaryfloatingpoint)
public macro RAW_staticbuff_binaryfloatingpoint_type<T:BinaryFloatingPoint>() = #externalMacro(module:"RAW_macros", type:"RAW_staticbuff_binaryfloatingpoint_type_macro")

public protocol RAW_encoded_fixedwidthinteger:RAW_native, RAW_staticbuff where RAW_native_type:FixedWidthInteger {}

extension RAW_encoded_fixedwidthinteger where Self:ExpressibleByIntegerLiteral {
	public init(integerLiteral value:RAW_native_type) {
		self.init(RAW_native:value)
	}
}

public protocol RAW_encoded_binaryfloatingpoint:RAW_native, RAW_staticbuff where RAW_native_type:BinaryFloatingPoint {}

extension RAW_encoded_binaryfloatingpoint where Self:ExpressibleByFloatLiteral {
	public init(floatLiteral value:RAW_native_type) {
		self.init(RAW_native:value)
	}
}
