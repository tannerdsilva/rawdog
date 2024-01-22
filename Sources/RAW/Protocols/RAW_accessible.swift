public protocol RAW_accessible:RAW_encodable {
	/// allows mutating access to the raw representation of the static buffer type.
	mutating func RAW_access_mutating<R>(_ body:(inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R
}

extension RAW_accessible {
	public mutating func RAW_encode(count: inout size_t) {
		RAW_access_mutating({ buffer in
			count += buffer.count
		})
	}
	@discardableResult public mutating func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_access_mutating({ source in
			return RAW_memcpy(dest, source.baseAddress!, source.count)!.advanced(by:source.count).assumingMemoryBound(to:UInt8.self)
		})
	}
}