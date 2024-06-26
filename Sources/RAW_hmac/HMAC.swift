import RAW

public struct HMAC<H:RAW_hasher> {
	private var innerContext:RAW_hasher
	private var outerContext:RAW_hasher
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
				return try innerContext.finish()
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

	public mutating func finish() throws -> [UInt8] {
		let innerResult = try innerContext.finish()
		try outerContext.update(innerResult)
		return try outerContext.finish()
	}
}

extension RAW_hasher {
	public static func hmac<K,M>(key:borrowing K, message:borrowing M) throws -> [UInt8] where K:RAW_accessible, M:RAW_accessible {
		var hmac = try HMAC<Self>(key:key)
		try hmac.update(message:message)
		return try hmac.finish()
	}
}