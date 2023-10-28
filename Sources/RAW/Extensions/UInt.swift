extension UInt64:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
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
		self = UInt64(bigEndian:RAW_data!.load(as:UInt64.self))
	}
}

extension UInt32:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
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
		self = UInt32(bigEndian:RAW_data!.load(as:UInt32.self))
	}
}

extension UInt16:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
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
		self = UInt16(bigEndian:RAW_data!.load(as:UInt16.self))
	}
}

extension UInt8:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt8>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<UInt8>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<UInt8>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = RAW_data!.load(as:UInt8.self)
	}
}

extension UInt:RAW_encodable, RAW_decodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<UInt>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<UInt>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = UInt(bigEndian:RAW_data!.load(as:UInt.self))
	}
}