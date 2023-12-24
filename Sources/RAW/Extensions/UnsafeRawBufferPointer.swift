import func CRAW.memcpy;

// raw buffers essentially the same thing as a RAW_val because they contain a buffer of data and a corresponding length. so we can implement this protocol directly.
extension UnsafeRawBufferPointer:RAW_val {
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments.
	public init(RAW_val_size: size_t, RAW_val_data_ptr: UnsafeRawPointer) {
		self.init(start:RAW_val_data_ptr, count:RAW_val_size)
	}

	/// the data value
	public var RAW_val_data_ptr:UnsafeRawPointer {
		return UnsafeRawPointer(self.baseAddress!)
	}
	
	/// the length of the data value
	public var RAW_val_size:size_t {
		return self.count
	}
}

extension UnsafeBufferPointer:Equatable where Element == UInt8 {}
extension UnsafeBufferPointer:Hashable where Element == UInt8 {}
extension UnsafeBufferPointer:RAW_val where Element == UInt8 {
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments.
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_val_size: size_t, RAW_val_data_ptr: UnsafeRawPointer) {
		self.init(start:UnsafePointer(RAW_val_data_ptr.assumingMemoryBound(to: UInt8.self)), count:RAW_val_size)
	}
	
	/// the data value
	public var RAW_val_data_ptr:UnsafeRawPointer {
		return UnsafeRawPointer(self.baseAddress)!
	}
	
	/// the length of the data value
	public var RAW_val_size:size_t {
		return self.count
	}
}