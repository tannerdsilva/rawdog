public protocol RAW_hasher {
	static var RAW_hasher_blocksize:Int { get }
	
	associatedtype RAW_hasher_outputtype:RAW_staticbuff

	/// initialize a new instance of the hasher context
	init() throws
	/// update the hasher with new data from an UnsafeRawBufferPointer
	mutating func update(_ :UnsafeRawBufferPointer) throws
	/// finish a hasher by outputting to a pointer
	mutating func finish(into _:UnsafeMutableRawPointer) throws
}

extension RAW_hasher {
	public mutating func finish(into obj:inout Optional<RAW_hasher_outputtype>) throws {
		switch obj {
			case nil:
				obj = RAW_hasher_outputtype.RAW_staticbuff_theoretical_min()
				fallthrough
			default:
				try obj!.RAW_access_mutable(UnsafeMutableRawPointer.self) { outputPtr in
					try finish(into:outputPtr)
				}
		}
	}
}

// default implementations for RAW_hasher update variants
extension RAW_hasher {
	public mutating func update(_ inputData:UnsafeBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}
	
	public mutating func update(_ ptr:UnsafeRawPointer, count:Int) throws {
		try update(UnsafeRawBufferPointer(start:ptr, count:count))
	}
}

extension RAW_hasher {
	public mutating func update(_ inputData:UnsafeMutableBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}
	/// update the hasher with new data (accessible type)
	public mutating func update<A>(_ data:borrowing A) throws where A:RAW_accessible {
		try data.RAW_access_immutable { buffer in
			try update(buffer)
		}
	}
}

extension RAW_hasher where RAW_hasher_outputtype:RAW_staticbuff {
	/// hash a raw accessible type
	public static func hash<A>(_ data:borrowing A) throws -> RAW_hasher_outputtype where A:RAW_accessible {
		var hasher = try Self()
		try hasher.update(data)
		var output = RAW_hasher_outputtype.RAW_staticbuff_theoretical_min()
		try output.RAW_access_mutable(UnsafeMutableRawPointer.self) { outputPtr in
			try hasher.finish(into:outputPtr)
		}
		return output
	}
}