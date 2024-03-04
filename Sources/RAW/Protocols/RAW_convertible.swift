public typealias RAW_convertible = RAW_encodable & RAW_decodable;

/// protocol that represents a type that can initialize from a raw representation in memory.
public protocol RAW_decodable {

	/// initialize from the contents of a raw data buffer.
	/// the byte buffer SHOULD be considered comprehensive and exact, meaning that any failure to stride in full should result in a nil return.
	/// - note: the initializer may returrn nil if the value is considered invalid or malformed.
	init?(RAW_decode:UnsafeRawPointer, count:size_t)
}

/// a special decodable type that is capable of returning a decoded Self from an unbounded forward seeking buffer read.
public protocol RAW_decodable_unbounded {

	/// initialize from the contents of a raw data buffer that has no known boundaries on the forward end.
	/// - WARNING: this protocol is SUPER RIDICULOUSLY, IRRESPONSIBLY UNSAFE. Implement this ONLY if you know that you need it and why.
	static func RAW_decode(unbounded:inout UnsafeRawPointer) -> Self?
}

extension RAW_decodable {
	/// initialize from the contents of a raw data buffer, as a mutable buffer pointer.
	public init?(RAW_accessed ptr:UnsafeBufferPointer<UInt8>) {
		self.init(RAW_decode:ptr.baseAddress!, count:ptr.count)
	}
}

public protocol RAW_encodable {
	/// encodes the size of the given instance to a size_t inout parameter.
	borrowing func RAW_encode(count:inout size_t)

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the number of bytes returned in ``RAW_byte_count``.
	@discardableResult borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>
}