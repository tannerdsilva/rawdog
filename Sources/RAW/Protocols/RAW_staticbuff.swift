/// represents a raw binary value of a pre-specified, static length.
public protocol RAW_staticbuff:RAW_encodable, RAW_decodable, RAW_comparable {
	/// the type that will be used to represent the raw data.
	/// - note: this protocol assumes that the result of `MemoryLayout<Self.RAW_staticbuff_storetype>.size` is the true size of your static buffer data. behavior with this protocol is undefined if this is not the case.
	associatedtype RAW_staticbuff_storetype

	/// initialize the static buffer from a pointer to its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
	init(RAW_staticbuff_storetype:UnsafeRawPointer)

	/// returns a copy of the static buffer's raw representation store type.
	func RAW_staticbuff() -> RAW_staticbuff_storetype

	/// compare two static buffers. returns 0 if the buffers are equal, negative values if the left buffer is less than the right buffer, and positive values if the left buffer is greater than the right buffer.
	static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32
}

public struct RAW_staticbuff_iterator<T:RAW_staticbuff>:IteratorProtocol {
	public typealias Element = UInt8
	private let staticbuff:T
	private var index:size_t = 0
	public init(staticbuff:T) {
		self.staticbuff = staticbuff
	}
	public mutating func next() -> UInt8? {
		guard index < MemoryLayout<T.RAW_staticbuff_storetype>.size else {
			return nil
		}
		defer {
			index += 1
		}
		return staticbuff.RAW_access { buff, size in
			#if DEBUG
			assert(size == MemoryLayout<T.RAW_staticbuff_storetype>.size)
			#endif
			return buff.load(fromByteOffset:index, as:UInt8.self)
		}
	}
}

extension RAW_staticbuff {
	/// encodes the value to the specified pointer.
	public func RAW_encode(dest ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		return RAW_access { buff, _ in
			ptr.assumingMemoryBound(to:RAW_staticbuff_storetype.self).initialize(to:buff.assumingMemoryBound(to:RAW_staticbuff_storetype.self).pointee)
			return ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
		}
	}

	/// initialize a new static buffer from a given value of its raw representation store type.
	public init(RAW_staticbuff_storetype storeVal:RAW_staticbuff_storetype) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		self = withUnsafePointer(to:storeVal, {
			return Self.init(RAW_staticbuff_storetype:$0)
		})
	}

	public init(RAW_staticbuff_storetype_seeking storeVal:UnsafeMutablePointer<UnsafeRawPointer>) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		defer {
			storeVal.pointee = storeVal.pointee.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
		}
		self = Self.init(RAW_staticbuff_storetype:storeVal.pointee)
	}

	// extend a default implementation of the RAW_decodable size function.
	public func RAW_encoded_size() -> size_t {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif

		return MemoryLayout<RAW_staticbuff_storetype>.size
	}

	// extend a default implementation of the RAW_decodable initializer
	public init?(RAW_decode bytes:UnsafeRawPointer, count size:size_t) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		guard size == MemoryLayout<RAW_staticbuff_storetype>.size else {
			return nil
		}

		self.init(RAW_staticbuff_storetype:bytes.assumingMemoryBound(to:RAW_staticbuff_storetype.self))
	}

	// extend a default implementation of the RAW_comparable function
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
		#if DEBUG
		assert(lhs_count == MemoryLayout<RAW_staticbuff_storetype>.size)
		assert(rhs_count == MemoryLayout<RAW_staticbuff_storetype>.size)
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		return RAW_compare(lhs_data:lhs_data, rhs_data:rhs_data)
	}

	// applies the same RAW_compare function that is required by RAW_staticbuff, but advances the pointers by the size of the static buffer after the comparison is complete.
	public static func RAW_compare(lhs_data_seeking:UnsafeMutablePointer<UnsafeRawPointer>, rhs_data_seeking:UnsafeMutablePointer<UnsafeRawPointer>) -> Int32 {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		defer {
			lhs_data_seeking.pointee = lhs_data_seeking.pointee.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
			rhs_data_seeking.pointee = rhs_data_seeking.pointee.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
		}
		return RAW_compare(lhs_data:lhs_data_seeking, rhs_data:rhs_data_seeking)
	}
}