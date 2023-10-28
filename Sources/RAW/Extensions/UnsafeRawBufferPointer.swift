// raw buffers essentially the same thing as a RAW_val because they contain a buffer of data and a length. so we can implement this protocol directly.
extension UnsafeRawBufferPointer:RAW_val {
	/// the data value
	public var RAW_data:UnsafeRawPointer? {
		return UnsafeRawPointer(self.baseAddress)
	}
	/// the length of the data value
	public var RAW_size:UInt64 {
		return UInt64(self.count)
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided RAW_val
	init<R>(_ val:R) where R:RAW_val {
		self.init(start:val.RAW_data, count:Int(val.RAW_size))
	}
}

// the same applies for the mutable variant - just translate self to a non-mutable pointer.
extension UnsafeMutableRawBufferPointer:RAW_val {
	/// the data value
	public var RAW_data:UnsafeRawPointer? {
		return UnsafeRawPointer(self.baseAddress)
	}
	/// the length of the data value
	public var RAW_size:UInt64 {
		return UInt64(self.count)
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided RAW_val
	init<R>(_ val:R) where R:RAW_val {
		self.init(start:UnsafeMutableRawPointer(mutating:val.RAW_data), count:Int(val.RAW_size))
	}
}