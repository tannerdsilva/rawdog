import RAW

extension RAW_hasher {
	public static func hmac<K, M>(key:borrowing K, message:borrowing M) throws -> [UInt8] where K:RAW_accessible, M:RAW_accessible {
		let k_ipad = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: Int(Self.RAW_hasher_blocksize))
		let k_opad = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: Int(Self.RAW_hasher_blocksize))
		let tempDigest = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: Int(Self.RAW_hasher_outputsize))
		defer {
			tempDigest.initialize(repeating:0)
			k_ipad.initialize(repeating:0)
			k_opad.initialize(repeating:0)
			tempDigest.deallocate()
			k_ipad.deallocate()
			k_opad.deallocate()
		}

		var innerContext = try! Self.init()
		var outerContext = try! Self.init()
		try key.RAW_access { keyBuffer in
			// prepare the key and pads
			if (keyBuffer.count > Self.RAW_hasher_blocksize) {
				// key is longer than block size so hash it first
				try innerContext.update(keyBuffer)
				try innerContext.finish(into: k_ipad.baseAddress!)
				innerContext = try! Self.init()
				_ = RAW_memcpy(k_opad.baseAddress!, k_ipad.baseAddress!, Int(Self.RAW_hasher_blocksize))
				_ = RAW_memset(k_ipad.baseAddress! + Self.RAW_hasher_outputsize, 0, Int(Self.RAW_hasher_blocksize - Self.RAW_hasher_outputsize))
				_ = RAW_memset(k_opad.baseAddress! + Self.RAW_hasher_outputsize, 0, Int(Self.RAW_hasher_blocksize - Self.RAW_hasher_outputsize))
			} else {
				_ = RAW_memcpy(k_ipad.baseAddress!, keyBuffer.baseAddress!, keyBuffer.count)
				_ = RAW_memcpy(k_opad.baseAddress!, keyBuffer.baseAddress!, keyBuffer.count)
				_ = RAW_memset(k_ipad.baseAddress! + keyBuffer.count, 0, Int(Self.RAW_hasher_blocksize - keyBuffer.count))
				_ = RAW_memset(k_opad.baseAddress! + keyBuffer.count, 0, Int(Self.RAW_hasher_blocksize - keyBuffer.count))
			}
		}

		// xor the key with the ipad and opad
		for i in 0..<Self.RAW_hasher_blocksize {
			k_ipad[i] ^= 0x36
			k_opad[i] ^= 0x5c
		}

		// inner hash
		try innerContext.update(k_ipad)
		try innerContext.update(message)
		try innerContext.finish(into: tempDigest.baseAddress!)

		// outer hash
		try outerContext.update(k_opad)
		try outerContext.update(tempDigest)
		return try [UInt8](unsafeUninitializedCapacity:Self.RAW_hasher_outputsize) { buffer, count in
			count = Self.RAW_hasher_outputsize
			try outerContext.finish(into: buffer.baseAddress!)
		}
	}
}