/// protocol that represents a type that can initialize from a raw representation.
public protocol RAW_decodable {

	/// initialize from the contents of a raw data buffer.
	/// the byte buffer SHOULD be considered comprehensive and exact, meaning that any failure to stride in full should result in a nil return.
	/// - note: the initializer may returrn nil if the value is considered invalid or malformed.
	init?(RAW_decode bytes:UnsafeRawPointer, size:size_t)
}

extension RAW_decodable {
	/// initialize the value from an array of bytes.
	public init?(RAW_decode bytes:[UInt8]) {
		self.init(RAW_decode:bytes, size:bytes.count)
	}

	/// initialize the value from the bytes.
	public init?(RAW_decode bytes:UnsafePointer<UInt8>, size:size_t) {
		self.init(RAW_decode:bytes, size:size)
	}
}

public protocol RAW_encodable {
	/// returns the amount of bytes that are required to encode the value of the instance.
	func RAW_encoded_size() -> size_t

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the number of bytes returned in ``RAW_encoded_size``.
	func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
}

extension RAW_encodable {

	@available(*, deprecated)
	func RAW_encode(ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return self.RAW_encode(dest:ptr)
	}

	/// encode the value to a raw representation and return the bytes as an array.
	public func RAW_encoded_bytes() -> [UInt8] {
		let encodedSize = self.RAW_encoded_size()
		return [UInt8](unsafeUninitializedCapacity:encodedSize, initializingWith: { bufferPtr, initializedCount in
			let bufferWritePtr = UnsafeMutableRawPointer(bufferPtr.baseAddress!)
			initializedCount = encodedSize
			#if DEBUG
			let resultPtr = self.RAW_encode(dest:bufferWritePtr)
			assert(bufferWritePtr.distance(to:resultPtr) == encodedSize)
			#else
			_ = self.RAW_encode(ptr:bufferWritePtr)
			#endif
		})
	}
}