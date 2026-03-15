// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

// rawdog v22 changed the fundamental architecture of the core RAW protocols. in order to keep the build system working for users across the transision, old names are still supported with deprecation warnings. this file contains the old names and deprecation warnings, and should be removed in a future release after users have had time to transition to the new names.
extension RAW_accessible_immutable {
	@available(*, deprecated, renamed:"RAW_access_immutable")
	public borrowing func RAW_access<R, E>(as:UnsafeBufferPointer<UInt8>.Type, _ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeBufferPointer<UInt8>.self, body)
	}
	@available(*, deprecated, renamed:"RAW_access_immutable")
	public borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeBufferPointer<UInt8>.self, body)
	}

}
extension RAW_accessible_mutable {
	@available(*, deprecated, renamed:"RAW_access_mutable")
	public mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R {
		return try RAW_access_mutable(UnsafeMutableBufferPointer<UInt8>.self, body)
	}
	@available(*, deprecated, renamed:"RAW_access_mutable")
	public mutating func RAW_access_mutating<R, E>(as:UnsafeMutableBufferPointer<UInt8>.Type,_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R {
		return try RAW_access_mutable(UnsafeMutableBufferPointer<UInt8>.self, body)
	}
}

extension RAW_comparable {
	@available(*, deprecated, renamed:"RAW_compare(_:_:)")
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
		return RAW_compare(UnsafeRawBufferPointer(start:lhs_data, count:lhs_count), UnsafeRawBufferPointer(start:rhs, count:rhs_count))
	}
}

extension RAW_decodable {
	@available(*, deprecated, renamed:"init(RAW_decode:)")
	public init?(RAW_decode ptr:UnsafeRawPointer, count:RAW.size_t) {
		self.init(RAW_decode:UnsafeRawBufferPointer(start:ptr, count:count))
	}
	/// initialize from the contents of a raw data buffer, as a mutable buffer pointer.
	@available(*, deprecated, renamed:"init(RAW_decode:)")
	public init?(RAW_accessed buff:UnsafeBufferPointer<UInt8>) {
		self.init(RAW_decode:UnsafeRawBufferPointer(buff))
	}
}

extension RAW_staticbuff {
	@available(*, deprecated, renamed:"RAW_fixed_type")
	typealias RAW_staticbuff_storetype = RAW_fixed_type

	@available(*, deprecated, renamed:"init(RAW_decode:)")
	public init(RAW_staticbuff ptr:UnsafeRawPointer) {
		self.init(RAW_decode:UnsafeRawBufferPointer(start:ptr, count:MemoryLayout<RAW_fixed_type>.size))!
	}
	@available(*, deprecated)
	public init(RAW_staticbuff buff:Self) {
		self = buff
	}
	@available(*, deprecated, message:"seek yourself")
	public init(RAW_staticbuff_seeking storeVal:UnsafeMutablePointer<UnsafeRawPointer>) {
		#if DEBUG
		assert(MemoryLayout<RAW_fixed_type>.size == MemoryLayout<RAW_fixed_type>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_fixed_type>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		defer {
			storeVal.pointee = storeVal.pointee.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
		self = Self.init(RAW_staticbuff:storeVal.pointee)
	}
	@available(*, deprecated, renamed:"RAW_staticbuff_theoretical_min()")
	public static func RAW_staticbuff_zeroed() -> Self {
		return Self.RAW_staticbuff_theoretical_min()
	}

	@available(*, deprecated, renamed:"RAW_access_immutable")
	public borrowing func RAW_access_staticbuff<R, E>(_ body:(UnsafeRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_immutable(UnsafeRawPointer.self, body)
	}
	@available(*, deprecated, renamed:"RAW_access_mutable")
	mutating func RAW_access_staticbuff_mutating<R, E>(_ body:(UnsafeMutableRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_mutable(UnsafeMutableRawPointer.self, body)
	}
}

extension RAW_native {
	@available(*, deprecated, renamed:"init(RAW_native_type:)")
	public init(RAW_native type:RAW_native_type) {
		self = .init(RAW_native_type:type)
	}
	consuming func RAW_native() -> RAW_native_type {
		return self.RAW_native_type()
	}
}