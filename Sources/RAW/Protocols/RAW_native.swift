// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
/// a protocol that is applied on types that represent an explicit encoding scheme of a native type. these types can include things like 
public protocol RAW_native {
	associatedtype RAW_native_type
	init(RAW_native:RAW_native_type)
	func RAW_native() -> RAW_native_type
}

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