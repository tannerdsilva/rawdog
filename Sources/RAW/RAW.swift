// written by tanner silva in 2023 (c) all rights reserved.

// rawdog is a swift library that makes it easy to encode and decode programming objects from C-like memory representations.

import struct CRAW.size_t
public typealias size_t = CRAW.size_t

import func CRAW.memcmp
import func CRAW.memcpy
public let RAW_memcmp = CRAW.memcmp
public let RAW_memcpy = CRAW.memcpy

@ConcatBufferType(Int, Int)
struct DatePairHash {
	let date:Int
	let hash:Int
}


/// a default implementation of the ``RAW_val`` protocol.
@frozen public struct RAW:RAW_val {
	/// the raw data that the structure instance represents.
	public let RAW_data:UnsafeRawPointer
	
	/// the size of the data that the structure instance represents.
	public let RAW_size:size_t

	/// creates a new RAW object from a given size and pointer.
	public init(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		self.RAW_data = RAW_data
		self.RAW_size = RAW_size.pointee
	}
}

extension RAW:RAW_encodable {
	/// adds the size of the raw memory representation to the given pointer.
    public func addRAW_val_size(into size: inout size_t) {
		size += self.RAW_size

    }

	/// copies the raw memory representation into the given buffer.
    public func copyRAW_val(into buffer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return memcpy(buffer, self.RAW_data, self.RAW_size)
    }

	/// allow for encodable access to the raw data.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		return try withUnsafePointer(to:self.RAW_size) { sizePtr in
			return try valFunc(self.RAW_data, sizePtr)
		}
	}
}

extension RAW:RAW_decodable {
	/// creates a new RAW object from a given size and pointer.
	public init(RAW_size:UnsafePointer<size_t>, RAW_data:UnsafeRawPointer) {
		self.RAW_data = RAW_data
		self.RAW_size = RAW_size.pointee
	}
}

// sequence conformance for RAW_val. allows for convenient iteration.
extension RAW:Sequence {

	/// returns a new iterator that will stride the contents of the RAW_val.
	public func makeIterator() -> RAW_iterator {
		return RAW_iterator(self)
	}

	/// an object that strides through the contents of a RAW_val.
	public struct RAW_iterator:IteratorProtocol {
		/// the sequence element for this iterator is UInt8
		public typealias Element = UInt8

		// represents the memory (byte buffer) that this iterator is striding through.
		private let memory:UnsafeRawBufferPointer
		// the size of the data that this iterator is striding through.
		private var size:size_t
		// the current index of the iterator.
		private var i:size_t = 0
		// creates a new iterator based on the memory contents of a given ``RAW_val``.
		internal init<R>(_ val:R) where R:RAW_val {
			self.memory = UnsafeRawBufferPointer(val)
			self.size = val.RAW_size
		}

		/// returns the next element in the sequence, or nil if there are no more elements.
		public mutating func next() -> Self.Element? {
			if (i >= size) {
				return nil
			} else {
				defer {
					i += 1;
				}
				return self.memory[i]
			}
		}
	}
}

// collection conformances for RAW_val, allows for convenient random access.
extension RAW:Collection {
	/// the start index for this collection is zero.
	public var startIndex:Int {
		return 0
	}

	/// the end index for this collection is the size of the ``RAW_val``.
	public var endIndex:Int {
		return Int(self.RAW_size)
	}

	/// returns the element at the given index.
	public subscript(position:Int) -> UInt8 {
		return self.RAW_data.assumingMemoryBound(to:UInt8.self).advanced(by:position).pointee
	}

	/// returns the index after the given index.
	public func index(after i:Int) -> Int {
		return i + 1
	}
}