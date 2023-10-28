extension Double:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt64>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<UInt64>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<UInt64>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Double(bitPattern:RAW_data!.load(as:UInt64.self))
	}
}

extension Float16:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt16>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<UInt16>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<UInt16>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Float16(bitPattern:RAW_data!.load(as:UInt16.self))
	}
}

extension Float32:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bitPattern) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt32>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<UInt32>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<UInt32>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Float32(bitPattern:RAW_data!.load(as:UInt32.self))
	}
}