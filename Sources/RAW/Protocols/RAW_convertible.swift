// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
public typealias RAW_convertible = RAW_encodable & RAW_decodable;

// MARK: decode
public protocol RAW_decodable {
	/// initialize from the contents of a raw data buffer.
	/// - NOTE: the length of the buffer must be exactly the size of the type.
	/// - NOTE: it is expected and REQUIRED that the initializer returns nil if the buffer is not the exact correct length.
	init?(RAW_decode:UnsafeRawBufferPointer)
}

// convenience initializer for decoding from a typed buffer pointer of UInt8.
extension RAW_decodable {
	public init?(RAW_decode:UnsafeBufferPointer<UInt8>) {
		self.init(RAW_decode:UnsafeRawBufferPointer(RAW_decode))
	}
	public init?(RAW_decode:UnsafeMutableBufferPointer<UInt8>) {
		self.init(RAW_decode:UnsafeRawBufferPointer(RAW_decode))
	}
	public init?(RAW_decode:UnsafeMutableRawBufferPointer) {
		self.init(RAW_decode:UnsafeRawBufferPointer(RAW_decode))
	}
}

public protocol RAW_encodable {
	/// encodes the size of the given instance to a size_t inout parameter.
	borrowing func RAW_encode(count:inout Int)

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the number of bytes returned in ``RAW_byte_count``.
	@discardableResult borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
}

extension RAW_encodable {
	@discardableResult public borrowing func RAW_encode(_:UnsafeMutablePointer<UInt8>.Type, dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_encode(UnsafeMutableRawPointer.self, dest:dest).assumingMemoryBound(to:UInt8.self)
	}
}
extension RAW_encodable {
	@discardableResult public borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_encode(UnsafeMutablePointer<UInt8>.self, dest:dest)
	}
}