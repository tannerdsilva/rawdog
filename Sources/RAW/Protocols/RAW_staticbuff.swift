// LICENSE MIT
// copyright (c) tanner silva 2025. all rights reserved.

/// represents a raw binary value of a pre-specified, static length.
public protocol RAW_staticbuff:RAW_convertible_fixed, RAW_comparable_fixed, RAW_accessible, Sendable {
	associatedtype RAW_fixed_type = RAW_staticbuff_storetype

	/// the type that will be used to represent the raw data.
	/// - note: this protocol assumes that the result of `MemoryLayout<Self.RAW_staticbuff_storetype>.size` is the true size of your static buffer data. behavior with this protocol is undefined if this is not the case.
	associatedtype RAW_staticbuff_storetype

	/// initialize the static buffer from a pointer to its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
	init(RAW_staticbuff:UnsafeRawPointer)

	init(RAW_staticbuff:consuming RAW_staticbuff_storetype)

	borrowing func RAW_access_staticbuff<R, E>(_ body:(UnsafeRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error

	mutating func RAW_access_staticbuff_mutating<R, E>(_ body:(UnsafeMutableRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error

	consuming func RAW_staticbuff() -> RAW_staticbuff_storetype

	static func RAW_staticbuff_zeroed() -> RAW_staticbuff_storetype
}

extension RAW_staticbuff {
	public static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		#if DEBUG
		assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
		assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
		assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
		#endif
		return RAW_memcmp(lhs_data, rhs_data, MemoryLayout<RAW_staticbuff_storetype>.size)
	}
}

extension RAW_staticbuff where Self:ExpressibleByArrayLiteral {
	public init(arrayLiteral elements:UInt8...) {
		#if DEBUG
		assert(elements.count == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
		#endif
		self.init(RAW_staticbuff:[UInt8](elements))
	}
}

extension RAW_staticbuff where Self:Hashable {
	public func hash(into hasher:inout Hasher) {
		RAW_access_staticbuff({ ptr in
			hasher.combine(bytes:UnsafeRawBufferPointer(start:ptr, count:MemoryLayout<RAW_staticbuff_storetype>.size))
		})
	}
}

extension RAW_staticbuff where Self:Equatable, Self:RAW_comparable_fixed {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access_staticbuff({ lhs_ptr in
			rhs.RAW_access_staticbuff({ rhs_ptr in
				RAW_compare(lhs_data:lhs_ptr, rhs_data:rhs_ptr) == 0
			})
		})
	}
}

extension RAW_staticbuff where Self:Comparable, Self:RAW_comparable_fixed {
	public static func < (lhs:Self, rhs:Self) -> Bool {
		return lhs.RAW_access_staticbuff({ lhs_ptr in
			rhs.RAW_access_staticbuff({ rhs_ptr in
				RAW_compare(lhs_data:lhs_ptr, rhs_data:rhs_ptr) < 0
			})
		})
	}
}

extension RAW_staticbuff {	
	public init(RAW_staticbuff_seeking storeVal:UnsafeMutablePointer<UnsafeRawPointer>) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		defer {
			storeVal.pointee = storeVal.pointee.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
		}
		self = Self.init(RAW_staticbuff:storeVal.pointee)
	}

	// extend a default implementation of the RAW_decodable initializer
	public init?(RAW_decode bytes:UnsafeRawPointer) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		self.init(RAW_staticbuff:bytes)
	}

	// extend a default implementation of the RAW_access_mutating function
	public mutating func RAW_access_mutating<R, E>(_ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try RAW_access_staticbuff_mutating { (ptr:UnsafeMutableRawPointer) throws(E) -> R in
			try body(UnsafeMutableBufferPointer(start:ptr.assumingMemoryBound(to:UInt8.self), count:MemoryLayout<RAW_staticbuff_storetype>.size))
		}
	}
}
