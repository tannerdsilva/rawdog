import func CRAW.memcpy;

extension Double:RAW_encodable, RAW_decodable, RAW_comparable, RAW_staticbuff {
	/// encodes the value to teh specified pointer.
	public func RAW_encode(ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return self.bitPattern.RAW_encode(ptr:ptr)
	}

	public static func RAW_compare<V>(_ lhs:V, _ rhs:V) -> Int32 where V : RAW_val {
		let doubleLeft = Self(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr)
		let doubleRight = Self(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr)
		if (doubleLeft < doubleRight) {
			return -1
		} else if (doubleLeft > doubleRight) {
			return 1
		} else {
			return 0
		}
	}

	public init(RAW_staticbuff_storetype:UnsafeRawPointer) {
		self = Self(bitPattern:UInt64(RAW_staticbuff_storetype:RAW_staticbuff_storetype))
	}

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

	/// sorts based on its native IEEE 754 representation and not its lexical representation.
	public static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
		let asLeftDouble = Double(bitPattern:UInt64(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr))
		let asRightDouble = Double(bitPattern:UInt64(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr))
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
	public func RAW_encode(ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return self.bitPattern.RAW_encode(ptr:ptr)
	}

    public static func RAW_compare<V>(_ lhs: V, _ rhs: V) -> Int32 where V : RAW_val {
		let doubleLeft = Self(RAW_staticbuff_storetype:lhs.RAW_val_data_ptr)
		let doubleRight = Self(RAW_staticbuff_storetype:rhs.RAW_val_data_ptr)
		if (doubleLeft < doubleRight) {
			return -1
		} else if (doubleLeft > doubleRight) {
			return 1
		} else {
			return 0
		}
    }

    public init(RAW_staticbuff_storetype:UnsafeRawPointer) {
		self = Self(bitPattern:UInt32(RAW_staticbuff_storetype:RAW_staticbuff_storetype))
    }

	/// the type of raw storage that this type uses.
	public typealias RAW_staticbuff_storetype = (UInt8, UInt8, UInt8, UInt8)
}