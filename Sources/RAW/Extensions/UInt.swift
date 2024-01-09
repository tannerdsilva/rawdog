import struct CRAW.size_t;
import func CRAW.memcpy;
import func CRAW.memcmp;

// extend the unsigned 64 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt64:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the unsigned 32 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt32:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the unsigned 16 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt16:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the unsigned 8 bit integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt8:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self = RAW_decode.load(as:Self.self)
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		dest.assumingMemoryBound(to:Self.self).initialize(to:self)
		return dest.advanced(by:MemoryLayout<RAW_fixed_type>.size)
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}

// extend the unsigned integer to conform to the raw static buffer protocol, as it is a fixed size type.
extension UInt:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bigEndian:RAW_decode.load(as:Self.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bigEndian) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<Self>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = Self
}