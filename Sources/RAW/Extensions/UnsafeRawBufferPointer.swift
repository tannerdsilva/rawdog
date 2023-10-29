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
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer?, RAW_size:UInt64) {
		self.init(start:UnsafeRawPointer(RAW_data), count:Int(RAW_size))
	}
}

extension UnsafeBufferPointer:Equatable where Element == UInt8 {}
extension UnsafeBufferPointer:Hashable where Element == UInt8 {}
extension UnsafeBufferPointer:RAW_val where Element == UInt8 {
	/// the data value
	public var RAW_data:UnsafeRawPointer? {
		return UnsafeRawPointer(self.baseAddress)
	}
	/// the length of the data value
	public var RAW_size:UInt64 {
		return UInt64(self.count)
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer?, RAW_size:UInt64) {
		self.init(start:UnsafePointer(RAW_data?.assumingMemoryBound(to: UInt8.self)), count:Int(RAW_size))
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
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer?, RAW_size:UInt64) {
		self.init(start:UnsafeMutableRawPointer(mutating:RAW_data), count:Int(RAW_size))
	}
}