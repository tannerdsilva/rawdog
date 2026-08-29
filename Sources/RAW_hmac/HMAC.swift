import RAW

public struct HMAC<H:RAW_hasher> {
	private var innerContext:H
	private var outerContext:H
	private init(inner:consuming H, outer:consuming H) {
		innerContext = inner
		outerContext = outer
	}
	private static func initiate(key:UnsafeRawPointer, count:Int) throws -> Self {
		var innerContext = try H.init()
		var outerContext = try H.init()
		var tmp:UInt8 = 0;
		var keyVar = key
		var keyScratch = H.RAW_hasher_outputtype(RAW_staticbuff_seeking:&keyVar)
		try keyScratch.RAW_access_mutable { keyScratchPtr in
			let useKeyPtr:UnsafePointer<UInt8>
			let useKeyCount:Int
			if (count > H.RAW_hasher_blocksize) {
				var keyContext = try H.init()
				try keyContext.update(key, count:count)
				try keyContext.finish(into:keyScratchPtr.baseAddress!)
				useKeyPtr = UnsafePointer(keyScratchPtr.baseAddress!)
				useKeyCount = keyScratchPtr.count
			} else {
				useKeyPtr = key.assumingMemoryBound(to:UInt8.self)
				useKeyCount = count
			}

			// ipad / opad processing

			for i in 0..<useKeyCount {
				tmp = useKeyPtr[i] ^ 0x5c;
				try outerContext.update([tmp])
				tmp = useKeyPtr[i] ^ 0x36;
				try innerContext.update([tmp])
			}
			for _ in useKeyCount..<H.RAW_hasher_blocksize {
				tmp = 0x5c;
				try outerContext.update([tmp])
				tmp = 0x36;
				try innerContext.update([tmp])
			}
		}
		return Self(inner:innerContext, outer:outerContext)
	}

	public init(key:UnsafeRawPointer, count:Int) throws {
		self = try Self.initiate(key:key, count:count)
	}
	
	public init<K>(key:borrowing K) throws where K:RAW_accessible {
		self = try key.RAW_access_immutable(UnsafeRawBufferPointer.self) { keyBuffer in
			return try Self.initiate(key:keyBuffer.baseAddress!, count:keyBuffer.count)
		}
	}

	public init<K>(key:UnsafePointer<K>) throws where K:RAW_accessible {
		self = try key.pointee.RAW_access_immutable(UnsafeRawBufferPointer.self) { keyBuffer in
			return try Self.initiate(key:keyBuffer.baseAddress!, count:keyBuffer.count)
		}
	}

	public mutating func finish(into ptr:UnsafeMutableRawPointer) throws {
		try innerContext.finish(into:ptr)
		try outerContext.update(ptr, count:MemoryLayout<H.RAW_hasher_outputtype>.size)
		try outerContext.finish(into:ptr)
	}

	public mutating func finish() throws -> H.RAW_hasher_outputtype {
		let size = MemoryLayout<H.RAW_hasher_outputtype.RAW_fixed_type>.size
		let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 1)
		defer { buffer.deallocate() }
		try innerContext.finish(into: buffer)
		var seekPtr = UnsafeRawPointer(buffer)
		let innerResult = H.RAW_hasher_outputtype(RAW_staticbuff_seeking: &seekPtr)
		try innerResult.RAW_access_immutable(UnsafeRawBufferPointer.self) {
			try outerContext.update($0)
		}
		try outerContext.finish(into: buffer)
		seekPtr = UnsafeRawPointer(buffer)
		return H.RAW_hasher_outputtype(RAW_staticbuff_seeking: &seekPtr)
	}
}

// update with data pointers
extension HMAC {
	public mutating func update(message inputData:UnsafeRawBufferPointer) throws {
		try innerContext.update(inputData)
	}
	
	public mutating func update(message inputData:UnsafeBufferPointer<UInt8>) throws {
		try innerContext.update(inputData)
	}
		
	public mutating func update(message data:UnsafeRawPointer, count:Int) throws {
		try innerContext.update(data, count:count)
	}
}

// update with raw accessible types
extension HMAC {
	public mutating func update<M>(message:borrowing M) throws where M:RAW_accessible {
		try innerContext.update(message)
	}
	
	public mutating func update<M>(message:UnsafePointer<M>) throws where M:RAW_accessible {
		try innerContext.update(message)
	}
}

extension RAW_hasher {
	public static func hmac<K, M>(key:borrowing K, message:borrowing M) throws -> RAW_hasher_outputtype where K:RAW_accessible, M:RAW_accessible {
		var hmac = try HMAC<Self>(key:key)
		try hmac.update(message:message)
		return try hmac.finish()
	}
}