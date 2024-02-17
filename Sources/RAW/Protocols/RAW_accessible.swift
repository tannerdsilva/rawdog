public protocol RAW_accessible:RAW_encodable {
	/// allows mutating access to the raw representation of the instance.
	mutating func RAW_access_mutating<R>(_ body:(inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R

	/// allows for non-mutating access to the raw representation of the instance.
	func RAW_access<R>(_ body:(UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R
}

extension RAW_accessible {
	public func RAW_encode(count:inout size_t) {
		RAW_access { buffer in
			count = buffer.count
		}
	}
	public func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_access { buffer in
			_ = RAW_memcpy(dest, buffer.baseAddress!, buffer.count)
			return dest + buffer.count
		}
	}
}