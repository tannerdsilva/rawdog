extension UnsafeMutableBufferPointer<UInt8>:RAW_accessible, RAW_encodable {
    public mutating func RAW_access_mutating<R>(_ body: (inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
		return try body(&self)
	}
}