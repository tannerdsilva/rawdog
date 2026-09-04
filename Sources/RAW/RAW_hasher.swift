// LICENSE MIT
// copyright (c) tanner silva 2025. all rights reserved.

import Darwin

/// a protocol that represents a hashing algorithm.
public protocol RAW_hasher {
	/// the block size of the hasher.
	static var RAW_hasher_blocksize:Int { get }

	/// the output type of the hasher.
	associatedtype RAW_hasher_outputtype:RAW_staticbuff & RAW_accessible_mutable

	/// initialize a new instance of the hasher context.
	init() throws
	/// update the hasher with new data from an UnsafeRawBufferPointer. this is the
	/// single required update primitive; every other update variant is a default
	/// implementation that funnels through this one.
	mutating func update(_ :UnsafeRawBufferPointer) throws
	/// finish a hasher by outputting to a pointer.
	mutating func finish(into _:UnsafeMutableRawPointer) throws
}

// default implementations for RAW_hasher update variants
extension RAW_hasher {
	/// update the hasher from a byte buffer.
	public mutating func update(_ inputData:UnsafeBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}

	/// update the hasher from a raw pointer and count.
	public mutating func update(_ ptr:UnsafeRawPointer, count:Int) throws {
		try update(UnsafeRawBufferPointer(start:ptr, count:count))
	}

	/// finish the hashing process and return the typed output value.
	/// the default implementation writes the digest into a temporary allocation and
	/// loads it back as ``RAW_hasher_outputtype``.
	public mutating func finish() throws -> RAW_hasher_outputtype {
		return try withUnsafeTemporaryAllocation(byteCount:MemoryLayout<RAW_hasher_outputtype.RAW_fixed_type>.size, alignment:MemoryLayout<RAW_hasher_outputtype>.alignment) { buffer in
			try finish(into: buffer.baseAddress!)
			var seekPtr = UnsafeRawPointer(buffer.baseAddress!)
			return RAW_hasher_outputtype(RAW_staticbuff_seeking: &seekPtr)
		}
	}
}

extension RAW_hasher {
	/// update the hasher from a mutable byte buffer.
	public mutating func update(_ inputData:UnsafeMutableBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}
	/// update the hasher with new data (accessible type)
	public mutating func update<A>(_ data:borrowing A) throws where A:RAW_accessible {
		try data.RAW_access_immutable(UnsafeRawBufferPointer.self) { buffer in
			try update(buffer)
		}
	}
	/// update the hasher with new data (unsafe pointer to accessible type)
	public mutating func update<A>(_ data:UnsafePointer<A>) throws where A:RAW_accessible {
		try data.pointee.RAW_access_immutable(UnsafeRawBufferPointer.self) { buffer in
			try update(buffer)
		}
	}
}
