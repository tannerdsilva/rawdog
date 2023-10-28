import func CRAW.memcmp;

/// represents a raw binary value of a statically fixed length
public protocol RAW_val_fixedsize:RAW_val {
	/// the fixed length of the values this type will produce
	static var RAW_size_fixed:UInt64 { get }
}

// default implementation for RAW_val_fixedsize.
extension RAW_val_fixedsize {
	// we map the static length to any given instance's length
	var RAW_size:UInt64 {
		return Self.RAW_size_fixed
	}
}

/// represents a raw binary value of a specified length
public protocol RAW_val:RAW_comparable, Hashable {
	/// the data value
	var RAW_data:UnsafeRawPointer? { get }
	/// the length of the data value
	var RAW_size:UInt64 { get }
}

// convenience static functions.
extension RAW_val {
	/// returns a ``RAW_val`` conformant object that represents a "null value". the returned data size is zero, and the data pointer is nil.
	public static func nullValue() -> any RAW_val {
		return RAW(0, nil)
	}
	/// loads a RAW_decodable type from the given ``RAW_val``. the ``RAW_val`` is consumed, and the returned value is the loaded value and the remaining ``RAW_val`` data.
	public func load<T>(_ type:T.Type) -> (T, RAW)? where T:RAW_decodable {
		let size = UInt64(MemoryLayout<T>.size)
		guard (self.RAW_size >= size) else {
			return nil
		}
		guard (self.RAW_data != nil) else {
			return nil
		}
		let value = T(RAW_size:size, RAW_data:self.RAW_data)
		guard (value != nil) else {
			return nil
		}
		return (value!, RAW(self.RAW_size - size, self.RAW_data!.advanced(by:Int(size))))
	}
}

// implements equatable and hashable.
extension RAW_val {
	// hashable implementation based on the byte contents of the ``RAW_val``.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(bytes:UnsafeRawBufferPointer(start:self.RAW_data, count:Int(self.RAW_size)))
	}
}

extension RAW_val {
	// default comparison implementation based on the byte contents of the ``RAW_val``.
	public static func RAW_compare(_ lhs:UnsafePointer<any RAW_val>, _ rhs:UnsafePointer<any RAW_val>) -> Int32 {
		let leftData = lhs.pointee.RAW_data
		let rightData = rhs.pointee.RAW_data
		switch (leftData, rightData) {
			case (nil, nil):
				return 0
			case (nil, _):
				return -1
			case (_, nil):
				return 1
			default:
				let leftSize = lhs.pointee.RAW_size
				let rightSize = rhs.pointee.RAW_size
				if (leftSize < rightSize) {
					return -1
				} else if (leftSize > rightSize) {
					return 1
				} else {
					return memcmp(lhs.pointee.RAW_data!, rhs.pointee.RAW_data!, Int(leftSize))
				}
		}
	}
}

extension RAW_val {
	// default equality implementation based on the byte contents of the ``RAW_val``.
	public static func < (lhs:Self, rhs:Self) -> Bool {
		return withUnsafePointer(to:(lhs as any RAW_val)) { leftPtr in
			return withUnsafePointer(to:(rhs as any RAW_val)) { rightPtr in
				return RAW_compare(leftPtr, rightPtr) < 0
			}
		}
	}
}

extension RAW_val {
	// default equality implementation based on the byte contents of the ``RAW_val``.
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return withUnsafePointer(to:(lhs as any RAW_val)) { leftPtr in
			return withUnsafePointer(to:(rhs as any RAW_val)) { rightPtr in
				return RAW_compare(leftPtr, rightPtr) == 0
			}
		}
	}
}
