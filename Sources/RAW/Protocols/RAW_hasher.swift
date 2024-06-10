public protocol RAW_hasher {
	static var RAW_hasher_outputsize:size_t { get }
	static var RAW_hasher_blocksize:size_t { get }

	/// initialize a new instance of the hasher context
	init() throws
	/// update the hasher with new data
	mutating func update(_ inputData:UnsafeRawBufferPointer) throws 
	/// update the hasher with new data
	@discardableResult mutating func finish(into output:UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer
}

extension RAW_hasher {
	/// update the hasher with new data (raw buffer)
	public mutating func update(_ inputData:UnsafeBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}
	public mutating func update(_ inputData:UnsafeMutableBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}
	/// update the hasher with new data (accessible type)
	public mutating func update<A>(_ data:A) throws where A:RAW_accessible {
		try data.RAW_access { buffer in
			try update(buffer)
		}
	}
	public mutating func finish() throws -> [UInt8] {
		return try [UInt8](unsafeUninitializedCapacity: Self.RAW_hasher_outputsize) { buffer, count in
			try finish(into:buffer.baseAddress!)
			count = Self.RAW_hasher_outputsize
		}
	}
	public static func hash<A>(_ data:A) throws -> [UInt8] where A:RAW_accessible {
		var hasher = try Self()
		try hasher.update(data)
		return try hasher.finish()
	}
}