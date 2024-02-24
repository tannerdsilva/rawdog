extension UnsafeMutableBufferPointer<UInt8>:RAW_accessible, RAW_encodable {
	public func RAW_access<R>(_ body: (UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R {
		return try body(UnsafeBufferPointer(self))
	}
}