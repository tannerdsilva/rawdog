/// represents a raw binary value of a pre-specified, static length.
public protocol RAW_staticbuff:RAW_convertible_fixed, RAW_comparable_fixed {
	associatedtype RAW_fixed_type = RAW_staticbuff_storetype

	/// the type that will be used to represent the raw data.
	/// - note: this protocol assumes that the result of `MemoryLayout<Self.RAW_staticbuff_storetype>.size` is the true size of your static buffer data. behavior with this protocol is undefined if this is not the case.
	associatedtype RAW_staticbuff_storetype

	var RAW_staticbuff:RAW_staticbuff_storetype { get }

	/// initialize the static buffer from a pointer to its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
	init(RAW_staticbuff:UnsafeRawPointer)

	/// allows mutating access to the raw representation of the static buffer type.
	mutating func RAW_access_mutating<R>(_ body:(UnsafeMutableRawPointer, size_t) throws -> R) rethrows -> R
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
	public init(RAW_staticbuff_seeking storeVal:inout UnsafeRawPointer) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		defer {
			storeVal = storeVal.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
		}
		self = Self.init(RAW_staticbuff:storeVal)
	}

	// extend a default implementation of the RAW_decodable initializer
	public init?(RAW_decode bytes:UnsafeRawPointer) {
		#if DEBUG
		assert(MemoryLayout<RAW_staticbuff_storetype>.size == MemoryLayout<RAW_staticbuff_storetype>.stride, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		assert(MemoryLayout<RAW_staticbuff_storetype>.alignment == 1, "please make sure you are using only Int8 or UInt8 based tuples for RAW_staticbuff storage types.")
		#endif
		self.init(RAW_staticbuff:bytes.assumingMemoryBound(to:RAW_staticbuff_storetype.self))
	}
}