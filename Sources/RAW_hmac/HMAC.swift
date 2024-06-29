import RAW

public struct HMAC<H:RAW_hasher> {
	private var innerContext:H
	private var outerContext:H
	public init<K>(key:borrowing K) throws where K:RAW_accessible {
		let scratch = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: Int(H.RAW_hasher_blocksize))
		defer { scratch.deallocate() }
		scratch.initialize(repeating:0x36)
		innerContext = try! H.init()
		outerContext = try! H.init()
		let useKey = try key.RAW_access { keyBuffer in
			if (keyBuffer.count > H.RAW_hasher_blocksize) {
				defer {
					innerContext = try! H.init()
				}
				try innerContext.update(keyBuffer)
				
				var useKey:H.RAW_hasher_outputtype? = nil
				try innerContext.finish(into:&useKey)
				return useKey!.RAW_access { keyBuffer in
					return [UInt8](RAW_decode:keyBuffer.baseAddress!, count:keyBuffer.count)
				}
			} else {
				return [UInt8](RAW_decode:keyBuffer.baseAddress!, count:keyBuffer.count)
			}
		}
		for (i, b) in useKey.enumerated() {
			scratch[i] ^= b
		}
		try innerContext.update(scratch)

		scratch.initialize(repeating:0x5c)
		for (i, b) in useKey.enumerated() {
			scratch[i] ^= b
		}
		try outerContext.update(scratch)
	}

	public init<K>(key:UnsafePointer<K>) throws where K:RAW_accessible {
		let scratch = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: Int(H.RAW_hasher_blocksize))
		defer { scratch.deallocate() }
		scratch.initialize(repeating:0x36)
		innerContext = try! H.init()
		outerContext = try! H.init()
		let useKey = try key.pointee.RAW_access { keyBuffer in
			if (keyBuffer.count > H.RAW_hasher_blocksize) {
				defer {
					innerContext = try! H.init()
				}
				try innerContext.update(keyBuffer)
				
				var useKey:H.RAW_hasher_outputtype? = nil
				try innerContext.finish(into:&useKey)
				return useKey!.RAW_access { keyBuffer in
					return [UInt8](RAW_decode:keyBuffer.baseAddress!, count:keyBuffer.count)
				}
			} else {
				return [UInt8](RAW_decode:keyBuffer.baseAddress!, count:keyBuffer.count)
			}
		}
		for (i, b) in useKey.enumerated() {
			scratch[i] ^= b
		}
		try innerContext.update(scratch)

		scratch.initialize(repeating:0x5c)
		for (i, b) in useKey.enumerated() {
			scratch[i] ^= b
		}
		try outerContext.update(scratch)
	}

	public mutating func update<M>(message:borrowing M) throws where M:RAW_accessible {
		try innerContext.update(message)
	}

	public mutating func finish() throws -> H.RAW_hasher_outputtype {
		var innerResult:H.RAW_hasher_outputtype? = nil
		try innerContext.finish(into:&innerResult)
		try innerResult!.RAW_access {
			try outerContext.update($0)
		}
		try outerContext.finish(into:&innerResult)
		return innerResult!
	}
}

extension RAW_hasher {
	public static func hmac<K, M>(key:borrowing K, message:borrowing M) throws -> RAW_hasher_outputtype where K:RAW_accessible, M:RAW_accessible {
		var hmac = try HMAC<Self>(key:key)
		try hmac.update(message:message)
		return try hmac.finish()
	}
}