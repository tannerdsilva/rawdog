extension Int64:RAW_decodable, RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int64>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int64>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<Int64>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int64(bigEndian:RAW_data!.load(as:Int64.self))
	}
}

extension Int32:RAW_decodable, RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int32>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int32>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<Int32>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int32(bigEndian:RAW_data!.load(as:Int32.self))
	}
}

extension Int16:RAW_decodable, RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int16>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int16>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<Int16>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int16(bigEndian:RAW_data!.load(as:Int16.self))
	}
}

extension Int8:RAW_decodable, RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int8>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int8>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<Int8>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int8(bigEndian:RAW_data!.load(as:Int8.self))
	}
}

extension Int:RAW_decodable, RAW_encodable {
	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.bigEndian) { ptr in
			return try ptr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<Int>.size) { bytePtr in
				return try valFunc(RAW(bytePtr, MemoryLayout<Int>.size))
			}
		}
	}
	
	/// required implementation.
	public init?(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		guard (RAW_size == UInt64(MemoryLayout<Int>.size)) else {
			return nil
		}
		guard (RAW_data != nil) else {
			return nil
		}
		self = Int(bigEndian:RAW_data!.load(as:Int.self))
	}
}