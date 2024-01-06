public typealias RAW_convertible = RAW_encodable & RAW_decodable;

/// protocol that represents a type that can initialize from a raw representation.
public protocol RAW_decodable {

	/// initialize from the contents of a raw data buffer.
	/// the byte buffer SHOULD be considered comprehensive and exact, meaning that any failure to stride in full should result in a nil return.
	/// - note: the initializer may returrn nil if the value is considered invalid or malformed.
	init?(RAW_decode:UnsafeRawPointer, size:size_t)
}

// implement convenience initializers for common types that represent byte buffers
extension RAW_decodable {
	public init?<S>(RAW_decode:S) where S:Sequence, S.Element == UInt8 {
		self.init(RAW_decode:Array(RAW_decode))
	}

	public init?<C>(RAW_decode:C) where C:Collection, C.Element == UInt8 {
		self.init(RAW_decode:Array(RAW_decode))
	}
	
	public init?(RAW_decode bytes:[UInt8]) {
		self.init(RAW_decode:bytes, size:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafePointer<UInt8>, size:size_t) {
		self.init(RAW_decode:bytes, size:size)
	}

	public init?(RAW_decode bytes:UnsafeMutableBufferPointer<UInt8>) {
		self.init(RAW_decode:bytes.baseAddress!, size:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafeMutableRawBufferPointer) {
		self.init(RAW_decode:bytes.baseAddress!, size:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafeRawBufferPointer) {
		self.init(RAW_decode:bytes.baseAddress!, size:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafeBufferPointer<UInt8>) {
		self.init(RAW_decode:bytes.baseAddress!, size:bytes.count)
	}
}

public protocol RAW_encodable {
	/// returns the amount of bytes that are required to encode the value of the instance.
	func RAW_encoded_size() -> size_t

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the number of bytes returned in ``RAW_encoded_size``.
	func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer

	/// encodes the value to the specified pointer.
	func RAW_access(_ accessFunc:(UnsafeRawPointer, size_t) throws -> Void) rethrows
}

extension RAW_encodable {
	@available(*, deprecated, message: "this function is deprecated. Use [UInt8](RAW_encodable:) instead.")
	public func RAW_encoded_bytes() -> [UInt8] {
		return [UInt8](RAW_encodable:self)
	}

	/// provides an open pointer to the encoded value. ideally, this is implemented to expose the direct memory of the value, but this is not required. the default implementation encodes the value to a temporary buffer and returns the pointer to that buffer.
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		let size = self.RAW_encoded_size()
		let ptr = [UInt8](unsafeUninitializedCapacity:size, initializingWith: { buff, size in
			#if DEBUG
			let startPtr = UnsafeMutableRawPointer(buff.baseAddress!)
			#endif

			let stridePtr = self.RAW_encode(dest:buff.baseAddress!)
			size = size
			
			#if DEBUG
			assert(abs(startPtr.distance(to:stridePtr)) == size, "self.RAW_encode(dest:) did not return a pointer that is the correct distance from the start pointer. expected: \(size), actual: \(abs(startPtr.distance(to:stridePtr))). type was: \(type(of:self))")
			#endif
		})
		return try accessFunc(ptr, size)
	}
}