// written by tanner silva in 2023 (c).
// rawdog is a swift library that makes it easy to encode and decode programming objects from C-like memory representations.

import struct CRAW.size_t
import func CRAW.memcmp
import struct CRAW.RAW_val

/// byte buffer representation struct.
public typealias RAW_val = CRAW.RAW_val

/// convertible (alias) protocol that encapsulates encodable and decodable protocols.
public typealias RAW_convertible = RAW_encodable & RAW_decodable

/// the protocol that enables initialization of programming objects from raw memory.
public protocol RAW_decodable {

	/// initializes a programming object from an existing ``RAW_val`` representation.
	init?(_ value:RAW_val)
}

/// the protocol that enables encoding of programming objects to raw memory.
public protocol RAW_encodable {

	/// encodes a programming object to a ``RAW_val`` representation. the ``RAW_val`` is passed to the ``valFunc`` closure, and the represented memory is only valid for the duration of the closure.
	func asRAW_val<R>(_ valFunc:(RAW_val) throws -> R) rethrows -> R
}

/// the protocol that enables comparison of programming objects from raw memory representations.
public protocol RAW_comparable {

	/// the compare function typealias that is used to compare two ``RAW_val``s of this type.
	typealias RAW_comparable_func_TYPE = @convention(c)(UnsafePointer<RAW_val>?, UnsafePointer<RAW_val>?) -> Int32 
	
	/// the static comparable function for this type
	static var RAW_comparable_func:RAW_comparable_func_TYPE { get }
}

// convenience static functions.
extension RAW_val {

	/// returns a ``RAW_val`` that represents a "null value". the returned data size is zero, and the data pointer is nil.
	public static func nullValue() -> RAW_val {
		return RAW_val(mv_size:0, mv_data:nil)
	}
}

// implement equatable and hashable.
extension RAW_val:Hashable, Equatable {
	/// hashable implementation based on the byte contents of the ``RAW_val``.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(bytes:UnsafeRawBufferPointer(start:self.mv_data, count:self.mv_size))
	}
	
	/// comparison implementation between two ``RAW_val``s. compares the ``RAW_val``s based on their byte contents.
	public static func == (lhs: RAW_val, rhs: RAW_val) -> Bool {
		if (lhs.mv_size == rhs.mv_size) {
			return memcmp(lhs.mv_data, rhs.mv_data, lhs.mv_size) == 0
		} else {
			return false
		}
	}
}

// array's that are storing UInt8's can be raw encoded.
extension Array:RAW_encodable where Element == UInt8 {

	/// retrieve the byte contents of the array as a ``RAW_val``.
	public func asRAW_val<R>(_ valFunc:(RAW_val) throws -> R) rethrows -> R {
		if let getThing = try self.withContiguousStorageIfAvailable({ someBytes in
			return try valFunc(RAW_val(mv_size:someBytes.count, mv_data:UnsafeMutableRawPointer(mutating:someBytes.baseAddress)))
		}) {
			return getThing
		} else {
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: self.count)
			defer { buffer.deallocate() }
			_ = buffer.initialize(from: self)
			return try valFunc(RAW_val(mv_size:self.count, mv_data:buffer.baseAddress))
		}
	}
}

// sequence conformance for RAW_val. allows for convenient iteration.
extension RAW_val:Sequence {

	/// an object that strides through the contents of a RAW_val.
	public struct Iterator:IteratorProtocol {

		/// the sequence element for this iterator is UInt8
		public typealias Element = UInt8

		// represents the memory (byte buffer) that this iterator is striding through.
		private let memory:UnsafeMutablePointer<UInt8>
		// the size of the data that this iterator is striding through.
		private var size:size_t
		// the current index of the iterator.
		private var i:size_t = 0
		// creates a new iterator based on the memory contents of a given ``RAW_val``.
		internal init(_ val:RAW_val) {
			self.memory = val.mv_data.assumingMemoryBound(to:UInt8.self)
			self.size = val.mv_size
		}

		/// returns the next element in the sequence, or nil if there are no more elements.
		public mutating func next() -> Self.Element? {
			if (i >= size) {
				return nil
			} else {
				defer {
					i += 1;
				}
				return memory[i]
			}
		}
	}

	/// the individual element that this ``RAW_val`` sequence is composed of.
	public typealias Element = UInt8

	/// returns a new iterator that will stride the contents of the RAW_val.
	public func makeIterator() -> Iterator {
		return Iterator(self)
	}
}

// collection conformances for RAW_val, allows for convenient random access.
extension RAW_val:Collection {
	
	/// the index type for this collection is ``size_t``.
	public typealias Index = size_t

	/// the start index for this collection is zero.
	public var startIndex:Index {
		return 0
	}

	/// the end index for this collection is the size of the ``RAW_val``.
	public var endIndex:Index {
		return self.mv_size
	}

	/// returns the element at the given index.
	public subscript(position:Index) -> UInt8 {
		return self.mv_data.assumingMemoryBound(to:UInt8.self)[position]
	}

	/// returns the index after the given index.
	public func index(after i:Index) -> Index {
		return i + 1
	}
}