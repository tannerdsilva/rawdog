// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

/// a type that does not require any size arguments because the size is known at compile time via the RAW_fixed_type associated type.
public protocol RAW_fixed {
	/// the type that expresses the size of this type.
	/// - the size of this type is determined as ``MemoryLayout<RAW_fixed_type>.size``
	/// - note: stride and alignment are NOT considered in any part of the implementations of this protocol.
	associatedtype RAW_fixed_type
}

// default implementation for all RAW_comparable types - lexicographically sorted data
extension RAW_comparable where Self:RAW_fixed {
	public static func RAW_compare(_ lhs:UnsafeRawPointer, _ rhs:UnsafeRawPointer) -> Int32 {
		return RAW_compare(UnsafeRawBufferPointer(start:lhs, count:MemoryLayout<RAW_fixed_type>.size), UnsafeRawBufferPointer(start:rhs, count:MemoryLayout<RAW_fixed_type>.size))
	}
	public static func RAW_compare(_ lhs:UnsafeMutableRawPointer, _ rhs:UnsafeMutableRawPointer) -> Int32 {
		return RAW_compare(UnsafeRawBufferPointer(start:lhs, count:MemoryLayout<RAW_fixed_type>.size), UnsafeRawBufferPointer(start:rhs, count:MemoryLayout<RAW_fixed_type>.size))
	}
}

// default implementation for all RAW_accessible_immutable types - simply provides `UnsafeRawPointer` access to the raw bytes of the instance.
extension RAW_accessible_immutable where Self:RAW_fixed {
	public borrowing func RAW_access_immutable<R, E>(_:UnsafeRawPointer.Type, _ body:(UnsafeRawPointer) throws(E) -> R) throws(E) -> R {
		return try RAW_access_immutable(UnsafeRawBufferPointer.self) { buff throws(E) -> R in
			return try body(buff.baseAddress!)
		}
	}
}

// default implementation for all RAW_accessible_mutable types - simply provides `UnsafeMutableRawPointer` access to the raw bytes of the instance.
extension RAW_accessible_mutable where Self:RAW_fixed {
	public mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawPointer.Type, _ body:(UnsafeMutableRawPointer) throws(E) -> R) throws(E) -> R {
		return try RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buff throws(E) -> R in
			return try body(buff.baseAddress!)
		}
	}
}

// default implementation for all RAW_decodable types - simply loads the type from the raw pointer.
extension RAW_decodable where Self:RAW_fixed {
	public init(RAW_decode ptr:UnsafeRawPointer) {
		self.init(RAW_decode:UnsafeRawBufferPointer(start:ptr, count:MemoryLayout<RAW_fixed_type>.size))!
	}
}

// seeking decoders for RAW_fixed types - simply advances the pointer by the size of the fixed type and decodes the value from the original pointer.
extension RAW_decodable where Self:RAW_fixed {
	public init(RAW_decode ptrSeeker:UnsafeMutablePointer<UnsafeRawPointer>, seeking:UnsafeRawPointer.Type) {
		self.init(RAW_decode:ptrSeeker.pointee)
		ptrSeeker.pointee = (ptrSeeker.pointee + MemoryLayout<RAW_fixed_type>.size)
	}
	public init(RAW_decode ptr:UnsafeMutablePointer<UnsafeMutableRawPointer>, seeking:UnsafeMutableRawPointer.Type) {
		self.init(RAW_decode:ptr.pointee)
		ptr.pointee = (ptr.pointee + MemoryLayout<RAW_fixed_type>.size)
	}
	public init(RAW_decode ptrSeeker:UnsafeMutablePointer<UnsafePointer<UInt8>>, seeking:UnsafePointer<UInt8>.Type) {
		self.init(RAW_decode:ptrSeeker.pointee)
		ptrSeeker.pointee = (ptrSeeker.pointee + MemoryLayout<RAW_fixed_type>.size)
	}
	public init(RAW_decode ptr:UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>, seeking:UnsafeMutablePointer<UInt8>.Type) {
		self.init(RAW_decode:ptr.pointee)
		ptr.pointee = (ptr.pointee + MemoryLayout<RAW_fixed_type>.size)
	}
}