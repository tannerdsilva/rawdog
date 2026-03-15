// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

/// a protocol for variable-length access to raw data.
public typealias RAW_accessible = RAW_accessible_mutable & RAW_accessible_immutable

// MARK: immutable access
/// protocol for immutable access to raw contiguous data.
public protocol RAW_accessible_immutable:RAW_encodable {
	/// allows for non-mutating access to the raw representation of the instance through an raw buffer pointer.
	borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

// default implementation for all RAW_accessible_immutable types - implements `UnsafeBufferPointer<UInt8>` access from the underlying `UnsafeRawBufferPointer` access.
extension RAW_accessible_immutable {
	public borrowing func RAW_access_immutable<R, E>(_:UnsafeBufferPointer<UInt8>.Type, _ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeRawBufferPointer.self) { buff throws(E) -> R in
			return try body(.init(start:buff.baseAddress?.assumingMemoryBound(to:UInt8.self), count:buff.count))
		}
	}
}

// RAW_encodable implementation for all RAW_accessible_immutable types - simply copies the raw bytes to the destination buffer.
extension RAW_accessible_immutable where Self:RAW_encodable {
	public borrowing func RAW_encode(count:inout Int) {
		RAW_access_immutable { buffer in
			count = buffer.count
		}
	}
	public borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return RAW_access_immutable(UnsafeRawBufferPointer.self) { buffer in
			_ = RAW_memcpy(dest, buffer.baseAddress!, buffer.count)
			return dest + buffer.count
		}
	}
}

extension RAW_accessible_immutable where Self:Hashable {
	public func hash(into hasher:inout Hasher) {
		RAW_access_immutable(UnsafeRawBufferPointer.self) { buff in
			hasher.combine(bytes:buff)
		}
	}
}

// MARK: mutable access
public protocol RAW_accessible_mutable:RAW_accessible_immutable {
	/// allows for mutating access to the raw representation of the instance through an raw buffer pointer.
	mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error
}

// default implementation for all RAW_accessible_mutable types - implements `UnsafeMutableBufferPointer<UInt8>` access from the underlying `UnsafeMutableRawBufferPointer` access.
extension RAW_accessible_mutable {
	public mutating func RAW_access_mutable<R, E>(_:UnsafeMutableBufferPointer<UInt8>.Type, _ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buff throws(E) -> R in
			return try body(.init(start:buff.baseAddress?.assumingMemoryBound(to:UInt8.self), count:buff.count))
		}
	}
}

// MARK: legacy & convenience
// default implementation for all RAW_accessible_immutable types - simply provides `UnsafeBufferPointer<UInt8>` access to the raw bytes of the instance when a type is not specified.
extension RAW_accessible_immutable {
	public borrowing func RAW_access_immutable<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeBufferPointer<UInt8>.self, body)
	}
}
// default implementation for all RAW_accessible_mutable types - simply provides `UnsafeMutableBufferPointer<UInt8>` access to the raw bytes of the instance when a type is not specified.
extension RAW_accessible_mutable {
	public mutating func RAW_access_mutable<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(UnsafeMutableBufferPointer<UInt8>.self, body)
	}
}