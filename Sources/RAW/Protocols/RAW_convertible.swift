/// convertible (alias) protocol that encapsulates encodable and decodable protocols.
public typealias RAW_convertible = RAW_encodable & RAW_decodable

/// protocol that represents a type that can initialize from a raw representation.
public protocol RAW_decodable {

	/// initialize the value from the raw value buffer.
	/// - note: it is possible that the value buffer is larger than the bytes needed to encode the frontmost value in the buffer.
	static func RAW_decode(ptr:UnsafeRawPointer, size:size_t, stride:inout size_t) -> Self?
}

extension RAW_decodable {

	init?<E>(RAW_decode encodableType:E) where E:RAW_encodable {
		let bytes = encodableType.RAW_encoded_bytes()
		let byteSize:size_t = bytes.count
		var stride:size_t = 0
		guard let makeSelf = Self.RAW_decode(ptr:bytes, size:byteSize, stride:&stride), byteSize == stride else {
			return nil
		}
		self = makeSelf
	}
}

// LOOKS GOOD DO NOT TOUCH
public protocol RAW_encodable {
	func RAW_encoded_size() -> size_t

	/// encode the value to a raw representation.
	func RAW_encode(ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
}

extension RAW_encodable {

	/// encode the value to a raw representation and return the bytes as an array.
	public func RAW_encoded_bytes() -> [UInt8] {
		let encodedSize = self.RAW_encoded_size()
		return [UInt8](unsafeUninitializedCapacity:encodedSize, initializingWith: { bufferPtr, initializedCount in
			_ = self.RAW_encode(ptr:bufferPtr.baseAddress!)
			initializedCount = encodedSize
		})
	}
}