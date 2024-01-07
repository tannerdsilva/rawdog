public typealias RAW_convertible = RAW_encodable & RAW_decodable;

/// protocol that represents a type that can initialize from a raw representation.
public protocol RAW_decodable {

	/// initialize from the contents of a raw data buffer.
	/// the byte buffer SHOULD be considered comprehensive and exact, meaning that any failure to stride in full should result in a nil return.
	/// - note: the initializer may returrn nil if the value is considered invalid or malformed.
	init?(RAW_decode:UnsafeRawPointer, count:size_t)
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
		self.init(RAW_decode:bytes, count:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafePointer<UInt8>, count:size_t) {
		self.init(RAW_decode:bytes, count:count)
	}

	public init?(RAW_decode bytes:UnsafeMutableBufferPointer<UInt8>) {
		self.init(RAW_decode:bytes.baseAddress!, count:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafeMutableRawBufferPointer) {
		self.init(RAW_decode:bytes.baseAddress!, count:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafeRawBufferPointer) {
		self.init(RAW_decode:bytes.baseAddress!, count:bytes.count)
	}

	public init?(RAW_decode bytes:UnsafeBufferPointer<UInt8>) {
		self.init(RAW_decode:bytes.baseAddress!, count:bytes.count)
	}
}

public protocol RAW_encodable {
	/// returns the amount of bytes that are required to encode the value of the instance.
	func RAW_encoded_size() -> size_t

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the number of bytes returned in ``RAW_encoded_size``.
	func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer

	/// exposes the encoded bytes as an open byte buffer, with a specified closure access function.
	func RAW_access<R>(_:(UnsafeRawPointer, size_t) throws -> R) rethrows -> R
}

extension RAW_encodable {
	public func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
		var byteCount:size_t = 0 
		let asBytes = [UInt8](RAW_encodable:self, count_out:&byteCount)
		return try accessFunc(asBytes, byteCount)
	}
}