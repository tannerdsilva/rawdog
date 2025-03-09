// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
extension Array:RAW_accessible, RAW_encodable where Element == UInt8 {
    public mutating func RAW_access_mutating<R, E>(_ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
    	func accessBytes(_ unsafePtr:UnsafeMutablePointer<UInt8>, _ cnt:Int) throws(E) -> R where E:Swift.Error {
    		return try body(UnsafeMutableBufferPointer<UInt8>(start:unsafePtr, count:cnt))
    	}
		return try accessBytes(&self, count)
    }
	public borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
		func accessBytes(_ unsafePtr:UnsafePointer<UInt8>, _ cnt:Int) throws(E) -> R where E:Swift.Error {
    		return try body(UnsafeBufferPointer<UInt8>(start:unsafePtr, count:cnt))
    	}
    	return try withUnsafePointer(to:self) { (ptr:UnsafePointer<Self>) throws(E) -> R in
    		return try accessBytes(ptr.pointee, ptr.pointee.count)
    	}
	}
	public borrowing func RAW_encode(count cntVar: inout size_t) {
		cntVar += count
	}
	public borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return withUnsafeBufferPointer({ buff in
			_ = RAW_memcpy(dest, buff.baseAddress!, buff.count)!
			return dest.advanced(by:buff.count)
		})
	}
}

extension Array:RAW_decodable where Element == UInt8 {
	public init(RAW_decode ptr:UnsafeRawPointer, count:size_t) {
		let asByteBuffer = UnsafeBufferPointer<UInt8>(start:ptr.assumingMemoryBound(to:UInt8.self), count:count)
		self.init(asByteBuffer)
	}
}

extension Array:RAW_comparable where Element == UInt8 {}

extension Array where Element == UInt8 {
	public init<E>(RAW_encodable ptr:UnsafeMutablePointer<E>, byte_count_out:inout size_t) where E:RAW_encodable {
		self.init(RAW_encodables:ptr, encodables_count: 1, byte_count_out: &byte_count_out)
	}
	public init<E>(RAW_encodables ptr:UnsafeMutablePointer<E>, encodables_count:size_t, byte_count_out:inout size_t) where E:RAW_encodable {
		var encSize:size_t = 0
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