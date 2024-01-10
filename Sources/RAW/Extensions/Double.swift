import func CRAW.memcpy;

extension Double:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bitPattern:RAW_decode.load(as:RAW_fixed_type.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bitPattern) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// eight bytes
	public typealias RAW_fixed_type = UInt64
}

extension Float:RAW_convertible_fixed {
	public init?(RAW_decode: UnsafeRawPointer) {
		self.init(bitPattern:RAW_decode.load(as:RAW_fixed_type.self))
	}

	public func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return withUnsafePointer(to:self.bitPattern) { ptr in
			return RAW.RAW_memcpy(dest, ptr, MemoryLayout<RAW_fixed_type>.size)!.advanced(by:MemoryLayout<RAW_fixed_type>.size)
		}
	}

	// four bytes
	public typealias RAW_fixed_type = UInt32
}