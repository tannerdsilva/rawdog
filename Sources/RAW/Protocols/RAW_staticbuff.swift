/// represents a raw binary value of a pre-specified, static length.
public protocol RAW_staticbuff:RAW_encodable, RAW_decodable, RAW_comparable {
	/// the type that will be used to represent the raw data.
	/// - note: this protocol assumes that the result of `MemoryLayout<Self.RAW_staticbuff_storetype>.size` is the true size of your static buffer data. behavior with this protocol is undefined if this is not the case.
	associatedtype RAW_staticbuff_storetype

	/// initialize the static buffer from its raw representation. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
	init(RAW_staticbuff_storetype:UnsafeRawPointer)
}

extension RAW_staticbuff {
	/// initialize from the given raw buffer representation.
	public init?(RAW_decode bytes:UnsafeRawPointer, size:size_t) {
		guard size == MemoryLayout<RAW_staticbuff_storetype>.size else {
			return nil
		}
		self.init(RAW_staticbuff_storetype:bytes.assumingMemoryBound(to:RAW_staticbuff_storetype.self))
	}
}

// automatically implement the RAW_encoded_size property for types that conform to RAW_staticbuff.
extension RAW_encodable where Self:RAW_staticbuff {
	/// default implementation. returns the size of the static buffer storage type, since that is the size of the encoded value.
	public func RAW_encoded_size() -> size_t {
		return MemoryLayout<RAW_staticbuff_storetype>.size
	}
}