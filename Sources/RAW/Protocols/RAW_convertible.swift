/// convertible (alias) protocol that encapsulates encodable and decodable protocols.
public typealias RAW_convertible = RAW_encodable & RAW_decodable

/// the protocol that enables initialization of programming objects from raw memory.
/// - initializers may return nil if the memory is not valid for the given type.
public protocol RAW_decodable {
	/// initializes a new instance of the type from a given size and pointer.
	/// - it is assumed that this function will only return nil if the size is not valid for the type.
	init?(RAW_size:size_t, RAW_data:UnsafeRawPointer)
}

/// the protocol that enables encoding of programming objects to raw memory.
public protocol RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, any BinaryInteger) throws -> R) rethrows -> R
}