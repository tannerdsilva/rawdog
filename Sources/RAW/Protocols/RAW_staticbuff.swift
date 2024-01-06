/// represents a raw binary value of a pre-specified, static length.
public protocol RAW_staticbuff:RAW_encodable, RAW_decodable, RAW_comparable {
	/// the type that will be used to represent the raw data.
	/// - note: this protocol assumes that the result of `MemoryLayout<Self.RAW_staticbuff_storetype>.size` is the true size of your static buffer data. behavior with this protocol is undefined if this is not the case.
	associatedtype RAW_staticbuff_storetype

	/// initialize the static buffer from a pointer to its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
	init(RAW_staticbuff_storetype:UnsafeRawPointer)

	/// compare two static buffers. returns 0 if the buffers are equal, negative values if the left buffer is less than the right buffer, and positive values if the left buffer is greater than the right buffer.
	static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32
}

extension RAW_staticbuff {
	/// initialize a new static buffer from a given value of its raw representation store type.
	public init(RAW_staticbuff_storetype storeVal:RAW_staticbuff_storetype) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		self = withUnsafePointer(to:storeVal, {
			return Self.init(RAW_staticbuff_storetype:$0)
		})
	}

	public init(RAW_staticbuff_storetype_seeking storeVal:UnsafeMutablePointer<UnsafeRawPointer>) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
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
		#endif

		return MemoryLayout<RAW_staticbuff_storetype>.size
	}

	// extend a default implementation of the RAW_decodable initializer
	public init?(RAW_decode bytes:UnsafeRawPointer, size:size_t) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		guard size == MemoryLayout<RAW_staticbuff_storetype>.size else {
			return nil
		}

		self.init(RAW_staticbuff_storetype:bytes.assumingMemoryBound(to:RAW_staticbuff_storetype.self))
	}

	// extend a default implementation of the RAW_comparable function
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_size:size_t, rhs_data:UnsafeRawPointer, rhs_size:size_t) -> Int32 {
		#if DEBUG
		assert(lhs_size == MemoryLayout<RAW_staticbuff_storetype>.size)
		assert(rhs_size == MemoryLayout<RAW_staticbuff_storetype>.size)
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		return RAW_compare(lhs_data:lhs_data, rhs_data:rhs_data)
	}

	// applies the same RAW_compare function that is required by RAW_staticbuff, but advances the pointers by the size of the static buffer after the comparison is complete.
	public static func RAW_compare(lhs_data_seeking:UnsafeMutablePointer<UnsafeRawPointer>, rhs_data_seeking:UnsafeMutablePointer<UnsafeRawPointer>) -> Int32 {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		defer {
			lhs_data_seeking.pointee = lhs_data_seeking.pointee.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
			rhs_data_seeking.pointee = rhs_data_seeking.pointee.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
		}
		return RAW_compare(lhs_data:lhs_data_seeking, rhs_data:rhs_data_seeking)
	}
}

struct My4Struct:RAW_staticbuff {
    func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
			return withUnsafePointer(to:value) { valPtr in
				return RAW_memcpy(dest, valPtr, MemoryLayout<RAW_staticbuff_storetype>.size)!
			}
    }

	static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		return RAW_memcmp(lhs_data, rhs_data, MemoryLayout<RAW_staticbuff_storetype>.size)
	}

	typealias RAW_staticbuff_storetype = (UInt32, UInt32, UInt32, UInt32)
	
	let value:RAW_staticbuff_storetype

	init(RAW_staticbuff_storetype ptr:UnsafeRawPointer) {
		self.value = ptr.load(as:RAW_staticbuff_storetype.self)
	}
}

struct MyConcatThing:RAW_staticbuff {
	func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		var destPtr = dest
		destPtr = storage.0.RAW_encode(dest:destPtr)
		destPtr = storage.1.RAW_encode(dest:destPtr)
		return destPtr
	}
	
	let storage:(Double, UInt32)
	
	typealias RAW_staticbuff_storetype = (Double.RAW_staticbuff_storetype, UInt32.RAW_staticbuff_storetype)
	
	init(RAW_staticbuff_storetype ptr:UnsafeRawPointer) {
		var seekPtr = ptr
		self.storage = (
			Double(RAW_staticbuff_storetype_seeking:&seekPtr),
			UInt32(RAW_staticbuff_storetype_seeking:&seekPtr)
		)

		#if DEBUG
		assert(seekPtr == ptr.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size))
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
	}

	static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
		var lhs_seeker = lhs_data
		var rhs_seeker = rhs_data
		var compareResult:Int32 = 0

		compareResult += Double.RAW_compare(lhs_data_seeking:&lhs_seeker, rhs_data_seeking:&rhs_seeker)
		guard compareResult == 0 else {
			return compareResult
		}

		compareResult += UInt32.RAW_compare(lhs_data_seeking:&lhs_seeker, rhs_data_seeking:&rhs_seeker)
		guard compareResult == 0 else {
			return compareResult
		}

		#if DEBUG
		assert(lhs_seeker == lhs_data.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size))
		assert(rhs_seeker == rhs_data.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size))
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif

		// all members are equal. return the compare result, which should be 0.
		return compareResult
	}
}