// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

// MARK: RAW_accessible_immutable + RAW_accessible_mutable
extension Array:RAW_accessible_immutable, RAW_accessible_mutable, RAW_encodable where Element == UInt8 {
	public mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try Swift.withUnsafeMutableBytes(of:&self) { rawBuff throws(E) -> R in
			return try body(rawBuff)
		}
	}

	public borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		return try Swift.withUnsafeBytes(of:self) { rawBuff throws(E) -> R in
			return try body(rawBuff)
		}
	}

	public borrowing func RAW_encode(count cntVar:inout Int) {
		cntVar += count
	}

	@discardableResult public borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, destination dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return Swift.withUnsafeBytes(of:self) { buff in
			return RAW_memcpy(dest, buff.baseAddress, buff.count)
		}
	}
}

// MARK: RAW_decodable
extension Array:RAW_decodable where Element == UInt8 {
	public init(RAW_decode buff:UnsafeRawBufferPointer) {
		let asByteBuffer = UnsafeBufferPointer<UInt8>(start:buff.baseAddress?.assumingMemoryBound(to:UInt8.self), count:buff.count)
		self.init(asByteBuffer)
	}
}

// MARK: RAW_comparable
extension Array:RAW_comparable where Element == UInt8 {}

// MARK: encodable array initializers
extension Array where Element == UInt8 {
	public init<E>(RAW_encodable ptr:UnsafeMutablePointer<E>, byte_count_out:inout Int) where E:RAW_encodable {
		self.init(RAW_encodables:ptr, encodables_count: 1, byte_count_out: &byte_count_out)
	}
	public init<E>(RAW_encodables ptr:UnsafeMutablePointer<E>, encodables_count:Int, byte_count_out:inout Int) where E:RAW_encodable {
		var encSize:Int = 0
		var seeker = ptr
		for i in 0..<encodables_count {
			defer {
				seeker += 1
			}
			ptr.advanced(by: i).pointee.RAW_encode(count:&encSize)
		}
		byte_count_out = encSize

		self = Self(unsafeUninitializedCapacity: encSize, initializingWith: { buff, size in
			var readSeek = ptr
			var writeSeek = buff.baseAddress!
			for _ in 0..<encodables_count {
				defer {
					readSeek += 1
				}
				writeSeek = readSeek.pointee.RAW_encode(dest:writeSeek)
			}
			#if DEBUG
			assert(writeSeek == buff.baseAddress!.advanced(by: encSize), "unexpected seek length. this is unexpected and breaks the assumptions that allow this macro to work")
			#endif
			size = encSize
		})
	}
}
