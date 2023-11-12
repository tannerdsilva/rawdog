import func CRAW.memcpy;

// raw buffers essentially the same thing as a RAW_val because they contain a buffer of data and a length. so we can implement this protocol directly.
extension UnsafeRawBufferPointer:RAW_val {
	/// the data value
	public var RAW_data:UnsafeRawPointer {
		return UnsafeRawPointer(self.baseAddress!)
	}
	/// the length of the data value
	public var RAW_size:size_t {
		return self.count
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		self.init(start:UnsafeRawPointer(RAW_data), count:RAW_size.pointee)
	}
}

extension UnsafeBufferPointer:Equatable where Element == UInt8 {}
extension UnsafeBufferPointer:Hashable where Element == UInt8 {}
extension UnsafeBufferPointer:RAW_encodable where Element == UInt8 {}
extension UnsafeBufferPointer:RAW_val where Element == UInt8 {
	/// the data value
	public var RAW_data:UnsafeRawPointer {
		return UnsafeRawPointer(self.baseAddress)!
	}
	/// the length of the data value
	public var RAW_size:size_t {
		return self.count
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		self.init(start:UnsafePointer(RAW_data.assumingMemoryBound(to: UInt8.self)), count:RAW_size.pointee)
	}

	/// encodes the value into a RAW value representation.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.count) { sizePtr in
			return try valFunc(UnsafeRawPointer(self.baseAddress!), sizePtr)
		}
	}
}

// the same applies for the mutable variant - just translate self to a non-mutable pointer.
extension UnsafeMutableRawBufferPointer:RAW_val {
    public func addRAW_val_size(into size: inout size_t) {
		size += self.count
    }

    public func copyRAW_val(into buffer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		let count = self.count
		return RAW_memcpy(buffer, self.baseAddress!, count)!.advanced(by:count)
    }

	/// the data value.
	public var RAW_data:UnsafeRawPointer {
		return UnsafeRawPointer(self.baseAddress!)
	}
	/// the length of the data value.
	public var RAW_size:size_t {
		return self.count
	}
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided arguments.
	/// - parameter RAW_data: the data pointer
	/// - parameter RAW_size: the length of the data
	public init(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		self.init(start:UnsafeMutableRawPointer(mutating:RAW_data), count:RAW_size.pointee)
	}
}