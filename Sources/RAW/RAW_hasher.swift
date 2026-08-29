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
	/// update the hasher with new data from an UnsafeRawBufferPointer.
	mutating func update(_ :UnsafeRawBufferPointer) throws
	/// update the hasher with new data from an UnsafeBufferPointer<UInt8>.
	mutating func update(_ :UnsafeBufferPointer<UInt8>) throws
	/// update the hasher with new data with the specified data and length arguments.
	mutating func update(_ :UnsafeRawPointer, count:Int) throws
	/// finish a hasher by outputting to a pointer.
	mutating func finish(into _:UnsafeMutableRawPointer) throws
}

// default implementations for RAW_hasher update variants
extension RAW_hasher {
	public mutating func update(_ inputData:UnsafeBufferPointer<UInt8>) throws {
		try update(UnsafeRawBufferPointer(inputData))
	}

	public mutating func update(_ ptr:UnsafeRawPointer, count:Int) throws {
		try update(UnsafeRawBufferPointer(start:ptr, count:count))
	}
}

extension RAW_hasher {
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
