/// convertible (alias) protocol that encapsulates encodable and decodable protocols.
public typealias RAW_convertible = RAW_encodable & RAW_decodable

/// the protocol that enables initialization of programming objects from raw memory.
/// - initializers may return nil if the memory is not valid for the given type.
public protocol RAW_decodable {
	/// required implementation.
	init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?)
}

extension RAW_decodable {
	/// default implementation that calls the required initializer.
	public init?<R>(_ rawType:R) where R:RAW_val {
		self.init(RAW_size:rawType.RAW_size, RAW_data:rawType.RAW_data)
	}
}

/// the protocol that enables encoding of programming objects to raw memory.
public protocol RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R
}