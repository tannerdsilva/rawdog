import func CRAW.memcmp;

/// raw represented value
public protocol RAW_rep_val:RAW_convertible {
	associatedtype RAW_rep_val_type:RAW_convertible;

	init?(RAW_rep_val:RAW_rep_val_type)

	func RAW_rep_value() -> RAW_rep_val_type
}

extension RAW_rep_val {
	public init?(RAW_decode bytes:UnsafeRawPointer, count:size_t) {
		guard let rep = RAW_rep_val_type(RAW_decode:bytes, count:count) else {
			return nil
		}
		self.init(RAW_rep_val:rep)
	}

	public func RAW_encoded_size() -> size_t {
		return RAW_rep_value().RAW_encoded_size()
	}

	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return RAW_rep_value().RAW_encode(dest:dest)
	}
}