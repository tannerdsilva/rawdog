import func CRAW.memcmp;

/// represents a raw binary value of a specified length
public protocol RAW_val:Hashable, Collection, Sequence, RAW_encodable {
	/// pointer to the raw data representation.
	var RAW_data:UnsafeRawPointer { get }
	/// the length of the data value.
	var RAW_size:size_t { get }
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided RAW_val
	/// loads the value of the given type from the ``RAW_val``. the ``RAW_val`` is consumed, and the returned value is the loaded value and the remaining ``RAW_val`` data.
	init(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>)
	/// loads the value of the given type from the ``RAW_val``. the ``RAW_val`` is consumed, and the returned value is the loaded value and the remaining ``RAW_val`` data.
	mutating func consume<T>(_ type:T.Type) -> T? where T:RAW_decodable
}

extension RAW_val {
	/// ``RAW_val``'s can be encoded into themselves.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.RAW_size) { sizePtr in
			return try valFunc(self.RAW_data, sizePtr)
		}
	}
}

extension RAW_val {
	/// creates an overlapping UnsafeRawBufferPointer from a given memory region described by the provided RAW_val
	/// - parameter RAW_val: the RAW_val that describes the memory region
	public init<R>(_ RAW_val:R) where R:RAW_val {
		self = withUnsafePointer(to:RAW_val.RAW_size) { sizePtr in
			return Self.init(RAW_data:RAW_val.RAW_data, RAW_size:sizePtr)
		}
	}
}

extension RAW_val {
	/// loads a RAW_decodable type from the given ``RAW_val``. the ``RAW_val`` is consumed, and the returned value is the loaded value and the remaining ``RAW_val`` data.
	public mutating func consume<T>(_ type:T.Type) -> T? where T:RAW_decodable {
		var size = MemoryLayout<T>.size
		guard (size <= self.RAW_size) else {
			return nil
		}
		let value = T(RAW_data:self.RAW_data, RAW_size:&size)
		guard value != nil else {
			return nil
		}
		withUnsafePointer(to:self.RAW_size - size) { newSizePtr in
			self = Self.init(RAW_data:self.RAW_data.advanced(by:size), RAW_size:newSizePtr)
		}
		return value
	}
}

// implements equatable and hashable.
extension RAW_val {
	/// hashable implementation based on the byte contents of the ``RAW_val``.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(bytes:UnsafeRawBufferPointer(start:self.RAW_data, count:Int(self.RAW_size)))
	}
	/// this implementation has no correlation to the custom sort protocols that 
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs.asRAW_val { lhsDat, lhsSiz in
			return rhs.asRAW_val { rhsDat, rhsSiz in
				return memcmp(lhsDat, rhsDat, rhsSiz.pointee) == 0
			}
		}
	}
}