// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

/// represents a raw binary value of a pre-specified, static length.
public protocol RAW_staticbuff:RAW_fixed, RAW_comparable, RAW_convertible, RAW_accessible, Sendable {
	/// the theoretical maximum value of this type.
	static func RAW_staticbuff_theoretical_max() -> Self
	
	/// the theoretical minimum value of this type.
	static func RAW_staticbuff_theoretical_min() -> Self
	
	/// initialize a new instance of this type from the raw bytes of the fixed type.
	init(RAW_fixed_type:consuming RAW_fixed_type)
	
	/// returns the raw bytes of the fixed type that represents this instance.
	consuming func RAW_fixed_type() -> RAW_fixed_type
}

extension RAW_staticbuff {
	/// the default implementation of the bitwise NOT operator for all RAW_staticbuff types. this operator is defined as the bitwise NOT of the raw bytes of the fixed type that represents this instance.
	public static prefix func ~ (value:consuming Self) -> Self {
		return value.RAW_access_mutable(UnsafeMutableBufferPointer<UInt8>.self) { valuePtr in
			for i in 0..<valuePtr.count {
				valuePtr[i] = ~valuePtr[i]
			}
			return Self(RAW_decode:valuePtr)!
		}
	}
}