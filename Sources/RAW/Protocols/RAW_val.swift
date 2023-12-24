import func CRAW.memcmp;

/// represents a raw binary value of a specified length. this is primarily implemented with the existence of a pointer to the raw data and the length of the data.
/// - note: the ``RAW_val`` is not meant to contain the data itself, it is merely used as a vehicle for other types to transfer their internal storage into common transportable scheme.
/// - conforms to:
///		- ``Equatable``: __default implementation provided__. a RAW_val shall be equatable based on the raw byte values that it contains.
/// 	- ``Hashable``: __default implementation provided__. a RAW_val shall be hashable based on the raw byte values that it contains.
/// 	- ``Collection``: this allows for convenient random access of the byte contents of the ``RAW_val``.
/// 	- ``Sequence``: this allows for convenient iteration of the byte contents of the ``RAW_val``.
public protocol RAW_val:Hashable, Collection, Sequence {
	
	/// the length of the data value represented by this instance.
	var RAW_val_size:size_t { get }
	
	/// pointer to the raw data representation that this value is representing. the data is assumed to be in a contiguous, linear buffer.
	var RAW_val_data_ptr:UnsafeRawPointer { get }
	
	/// loads the value of the given type from the ``RAW_val``. the ``RAW_val`` is consumed, and the returned value is the loaded value and the remaining ``RAW_val`` data.
	init(RAW_val_size:size_t, RAW_val_data_ptr:UnsafeRawPointer)
}

extension RAW_val {
	
	/// initialize a ``RAW_val`` from another ``RAW_val``, while also advancing the pointer of the source ``RAW_val`` by the specified amount.
	/// - parameter from: the source ``RAW_val`` to initialize from.
	/// - parameter advancedBy: the amount of bytes to advance the source ``RAW_val`` by.
	@available(*, deprecated, message:"use explicit code instead.")
	public init<V>(from rawVal:V, advancedBy byteDelta:size_t) where V:RAW_val {
		self.init(RAW_val_size:rawVal.RAW_val_size - byteDelta, RAW_val_data_ptr:rawVal.RAW_val_data_ptr.advanced(by:byteDelta))
	}

	/// return a new Self instance that is advanced by the specified amount of bytes.
	/// - parameter by: the amount of bytes to advance the ``RAW_val`` by.
	@available(*, deprecated, message:"use explicit code instead.")
	public func advanced(by delta:size_t) -> Self {
		return Self(RAW_val_size:self.RAW_val_size - delta, RAW_val_data_ptr:self.RAW_val_data_ptr.advanced(by:delta))
	}

	/// mutate the ``RAW_val`` by advancing it by the specified amount of bytes.
	@available(*, deprecated, message:"use explicit code instead.")
	public mutating func advance(by delta:size_t) {
		self = self.advanced(by:delta)
	}
	
}

// default implements hashable.
extension RAW_val {
	/// hashable implementation based on the byte contents of the ``RAW_val``.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(bytes:UnsafeRawBufferPointer(start:self.RAW_val_data_ptr, count:Int(self.RAW_val_size)))
	}
	
	/// default implementation of equatable based on the byte contents of the ``RAW_val``. memcmp is used to compare the byte contents in contiguity.
	public static func == (lhs:Self, rhs:Self) -> Bool {
		guard lhs.RAW_val_size == rhs.RAW_val_size else {
			return false
		}
		return RAW_memcmp(lhs.RAW_val_data_ptr, rhs.RAW_val_data_ptr, lhs.RAW_val_size) == 0
	}
}