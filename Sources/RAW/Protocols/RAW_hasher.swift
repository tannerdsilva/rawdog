public protocol RAW_hasher<RAW_hasher_outputtype> {
	static var RAW_hasher_blocksize:size_t { get }

	associatedtype RAW_hasher_outputtype:RAW_staticbuff

	/// initialize a new instance of the hasher context
	init() throws
	/// update the hasher with new data from an UnsafeRawBufferPointer
	mutating func update(_ :UnsafeRawBufferPointer) throws
	/// update the hasher with new data from an UnsafeBufferPointer<UInt8>
	mutating func update(_ :UnsafeBufferPointer<UInt8>) throws
	/// update the hasher with new data with the specified data and length arguments
	mutating func update(_ :UnsafeRawPointer, count:size_t) throws
	/// update the hasher with new data
	mutating func finish<O>(into output:inout Optional<O>) throws where O:RAW_staticbuff, O.RAW_staticbuff_storetype == RAW_hasher_outputtype.RAW_staticbuff_storetype
}

// default implementations for RAW_hasher update variants
extension RAW_hasher {
	public mutating func update(_ inputData:UnsafeBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}
	
	public mutating func update(_ ptr:UnsafeRawPointer, count:size_t) throws {
		try update(UnsafeRawBufferPointer(start:ptr, count:count))
	}
}

extension RAW_hasher {
	public mutating func update(_ inputData:UnsafeMutableBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}
	/// update the hasher with new data (accessible type)
	public mutating func update<A>(_ data:A) throws where A:RAW_accessible {
		try data.RAW_access { buffer in
			try update(buffer)
		}
	}
	/// update the hasher with new data (unsafe pointer to accessible type)
	public mutating func update<A>(_ data:UnsafePointer<A>) throws where A:RAW_accessible {
		try data.pointee.RAW_access { buffer in
			try update(buffer)
		}
	}
	public static func hash<A>(_ data:A) throws -> RAW_hasher_outputtype where A:RAW_accessible {
		var hasher = try Self()
		try hasher.update(data)
		var output:RAW_hasher_outputtype? = nil
		try hasher.finish(into:&output)
		return output!
	}
}