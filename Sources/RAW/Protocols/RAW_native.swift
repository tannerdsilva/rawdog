/// a protocol that is applied on types that represent an explicit encoding scheme of a native type. these types can include things like 
public protocol RAW_native {
	associatedtype RAW_native_type
	init(RAW_native:RAW_native_type)
	mutating func RAW_native() -> RAW_native_type
}

public protocol RAW_encoded_fixedwidthinteger:RAW_native, RAW_staticbuff where RAW_native_type:FixedWidthInteger {}

public protocol RAW_encoded_binaryfloatingpoint:RAW_native, RAW_staticbuff where RAW_native_type:BinaryFloatingPoint {}