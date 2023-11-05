/// represents a raw binary value of a specified, fixed length
public protocol RAW_staticbuff:RAW_encodable, RAW_decodable {
	/// the type that will be used to represent the raw data.
	/// - note: the size of this type is what will be used to determine the size of the raw data.
	associatedtype RAW_staticbuff_storetype

	/// the size of the underlying storage type.
	static var RAW_staticbuff_size:size_t { get }

	/// initializes a new RAW_staticbuff from a given pointer. the length of the data is determined by the memory size of the ``RAW_staticbuff_storetype``.
	init?(RAW_data:UnsafeRawPointer?)
	
	/// directly initialize a new RAW_staticbuff directly from its underlying storage type.
	init(_:RAW_staticbuff_storetype)
}

extension RAW_staticbuff {
	/// creates a new RAW_fixedlength object from a given size and pointer.
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard RAW_size == MemoryLayout<RAW_staticbuff_storetype>.size else {
			return nil
		}
		self.init(RAW_data:RAW_data)
	}

	public static var RAW_staticbuff_size:size_t {
		return MemoryLayout<RAW_staticbuff_storetype>.size
	}

	/// creates a new value (of the types own static length) with the contents in the passed argument..
	public init?<R>(_ val:R) where R:RAW_encodable {
		let result = val.asRAW_val { rawValue in
			let newSelf = Self.init(RAW_size:rawValue.RAW_size, RAW_data:rawValue.RAW_data)
			return newSelf
		}
		
		switch result {
			case .some(let newSelf):
				self = newSelf
			case .none:
				return nil
		}
	}
}
