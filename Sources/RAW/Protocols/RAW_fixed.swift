/// a type that does not require any size arguments because the size is known at compile time via the RAW_fixed_type associated type.
public protocol RAW_fixed {
	/// the type that expresses the size of this type.
	/// - the size of this type is determined as ``MemoryLayout<RAW_fixed_type>.size``
	/// - note: stride and alignment are NOT considered in any part of the implementations of this protocol.
	associatedtype RAW_fixed_type
}

/// a RAW_convertible type that is also RAW_fixed.
public protocol RAW_convertible_fixed:RAW_convertible, RAW_fixed {
	init?(RAW_decode:UnsafeRawPointer)
}

extension RAW_convertible_fixed {
	public func RAW_encoded_size() -> size_t {
		return MemoryLayout<RAW_fixed_type>.size
	}

	public init?(RAW_decode ptr:UnsafeRawPointer, count:size_t) {
		guard count == MemoryLayout<RAW_fixed_type>.size else {
			return nil
		}
		self.init(RAW_decode:ptr)
	}
}