import struct CRAW.size_t;

// raw buffers essentially the same thing as a RAW_val because they contain a buffer of data and a length. so we can implement this protocol directly.
extension UnsafeRawBufferPointer:RAW_val {
	/// the data value
	public var RAW_data:UnsafeRawPointer? {
		return UnsafeRawPointer(self.baseAddress)
	}
	/// the length of the data value
	public var RAW_size:size_t {
		return self.count
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer?, RAW_size:size_t) {
		self.init(start:UnsafeRawPointer(RAW_data), count:RAW_size)
	}
}

extension UnsafeBufferPointer:Equatable where Element == UInt8 {}
extension UnsafeBufferPointer:Hashable where Element == UInt8 {}
extension UnsafeBufferPointer:RAW_encodable where Element == UInt8 {}
extension UnsafeBufferPointer:RAW_val where Element == UInt8 {
	/// the data value
	public var RAW_data:UnsafeRawPointer? {
		return UnsafeRawPointer(self.baseAddress)
	}
	/// the length of the data value
	public var RAW_size:size_t {
		return self.count
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer?, RAW_size:size_t) {
		self.init(start:UnsafePointer(RAW_data?.assumingMemoryBound(to: UInt8.self)), count:RAW_size)
	}

	/// encodes the value into a RAW value representation.
	public func asRAW_val<R>(_ valFunc: (RAW) throws -> R) rethrows -> R {
		try valFunc(RAW(self.baseAddress, self.count))
	}
}

// the same applies for the mutable variant - just translate self to a non-mutable pointer.
extension UnsafeMutableRawBufferPointer:RAW_val {
	/// the data value.
	public var RAW_data:UnsafeRawPointer? {
		return UnsafeRawPointer(self.baseAddress)
	}
	/// the length of the data value.
	public var RAW_size:size_t {
		return self.count
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments.
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer?, RAW_size:size_t) {
		self.init(start:UnsafeMutableRawPointer(mutating:RAW_data), count:Int(RAW_size))
	}
}