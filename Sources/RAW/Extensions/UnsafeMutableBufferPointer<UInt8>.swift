extension UnsafeMutableBufferPointer<UInt8>:RAW_accessible, RAW_encodable {
    public mutating func RAW_access_mutating<R>(_ body: (inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
		return try body(&self)
	}
	public func RAW_access<R>(_ body: (UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R {
		return try body(UnsafeBufferPointer(self))
	}
}