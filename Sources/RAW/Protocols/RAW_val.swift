import struct CRAW.rawval_t;
import func CRAW.rawval_init;

/// represents a raw binary value of a specified length
public protocol RAW_val {
	/// the data value
	var RAW_data:UnsafeRawPointer? { get }
	/// the length of the data value
	var RAW_size:UInt64 { get }
}

/// represents a raw binary value of a statically fixed length
public protocol RAW_val_fixedsize:RAW_val {
	/// the fixed length of the values this type will produce
	static var RAW_size_fixed:UInt64 { get }
}

extension RAW_val_fixedsize {
	// we map the static length to any given instance's length
	var RAW_size:UInt64 {
		return Self.RAW_size_fixed
	}
}

// convenience static functions.
extension RAW_val {
	/// returns a ``RAW_val`` conformant object that represents a "null value". the returned data size is zero, and the data pointer is nil.
	public static func nullValue() -> RAW_val {
		return rawval_init(0, nil);
	}
}