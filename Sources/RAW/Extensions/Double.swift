import func CRAW.memcpy;

extension Double:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

	/// initialize a double from a raw IEEE 754 representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Double(bitPattern:UInt64(bigEndian:RAW_data.load(as:UInt64.self)))
	}

	/// initialize a double from a raw IEEE 754 representation in memory.
	public init(RAW_staticbuff_storetype:RAW_staticbuff_storetype) {
		self = withUnsafePointer(to:RAW_staticbuff_storetype) { ptr in
			return ptr.withMemoryRebound(to:UInt64.self, capacity:1, {
				return Double(bitPattern:UInt64(bigEndian:$0.pointee))
			})
		}
	}

	/// retrieves the raw IEEE 754 representation of the double.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<UInt64>.size) { sizePtr in
				return try valFunc(ptr, sizePtr)
			}
		}
	}
	
	/// initialize a double from a raw IEEE 754 representation in memory.
	public init?(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard (RAW_size.pointee == MemoryLayout<UInt64>.size) else {
			return nil
		}
		self = .init(RAW_data:RAW_data)
	}

	/// sorts based on its native IEEE 754 representation and not its lexical representation.
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		let asLeftDouble = Double(bitPattern:UInt64(bigEndian:lhs.RAW_data.load(as:UInt64.self)))
		let asRightDouble = Double(bitPattern:UInt64(bigEndian:rhs.RAW_data.load(as:UInt64.self)))
		if (asLeftDouble < asRightDouble) {
			return -1
		} else if (asLeftDouble > asRightDouble) {
			return 1
		} else {
			return 0
		}
	}
}

extension Float:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)

	/// initialize a double from a raw IEEE 754 representation in memory.
	public init(RAW_data:UnsafeRawPointer) {
		self = Float(bitPattern:UInt32(bigEndian:RAW_data.load(as:UInt32.self)))
	}

	public init(RAW_staticbuff_storetype:RAW_staticbuff_storetype) {
		self = withUnsafePointer(to:RAW_staticbuff_storetype) { ptr in
			return ptr.withMemoryRebound(to:UInt32.self, capacity:1, {
				return Float(bitPattern:UInt32(bigEndian:$0.pointee))
			})
		}
	}

	/// retrieves the raw IEEE 754 representation of the float.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern.bigEndian) { ptr in
			return try withUnsafePointer(to:MemoryLayout<UInt32>.size) { sizePtr in
				return try valFunc(ptr, sizePtr)
			}
		}
	}
	
	/// initializes a float32 from a raw IEEE 754 representation in memory.
	public init?(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard (RAW_size.pointee == MemoryLayout<UInt32>.size) else {
			return nil
		}
		self = .init(RAW_data:RAW_data)
	}

	/// sorts based on its native IEEE 754 representation and not its lexical representation.
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		let asLeftFloat = Float(bitPattern:UInt32(bigEndian:lhs.RAW_data.load(as:UInt32.self)))
		let asRightFloat = Float(bitPattern:UInt32(bigEndian:rhs.RAW_data.load(as:UInt32.self)))
		if (asLeftFloat < asRightFloat) {
			return -1
		} else if (asLeftFloat > asRightFloat) {
			return 1
		} else {
			return 0
		}
	}
}