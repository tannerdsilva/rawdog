// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
extension UnsafeMutableRawBufferPointer:RAW_accessible, RAW_encodable {
	public borrowing func RAW_access<R>(_ body: (UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R {
		return try body(UnsafeBufferPointer(assumingMemoryBound(to:UInt8.self)))
	}

	public mutating func RAW_access_mutating<R>(_ body: (UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
		return try body(assumingMemoryBound(to:UInt8.self))
	}
}