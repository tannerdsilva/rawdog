// written by tanner silva in 2023 (c) all rights reserved.

// rawdog is a swift library that makes it easy to encode and decode programming objects from C-like memory representations.

import func CRAW.memcmp
import struct CRAW.size_t
public typealias size_t = CRAW.size_t

/// a default implementation of the ``RAW_val`` protocol.
@frozen public struct RAW:RAW_val {
	/// the raw data that the structure instance represents.
	public let RAW_data:UnsafeRawPointer?
	
	/// the size of the data that the structure instance represents.
	public let RAW_size:size_t

	/// creates a new RAW object from a given size and pointer.
	public init(RAW_data:UnsafeRawPointer?, RAW_size:size_t) {
		self.RAW_data = RAW_data
		self.RAW_size = RAW_size
	}
}

extension RAW:RAW_encodable {
	/// allow for encodable access to the raw data.
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		return try valFunc(self)
	}
}

extension RAW:RAW_decodable {
	/// creates a new RAW object from a given size and pointer.
	public init(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		self.RAW_data = RAW_data
		self.RAW_size = RAW_size
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
		return self.RAW_data!.assumingMemoryBound(to:UInt8.self).advanced(by:position).pointee
	}

	/// returns the index after the given index.
	public func index(after i:Int) -> Int {
		return i + 1
	}
}

extension RAW_encodable where Self:RAW_comparable {
	// default comparison implementation based on the byte contents of the ``RAW_val``.
	public static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32 {
		let leftData = lhs.RAW_data
		let rightData = rhs.RAW_data
		switch (leftData, rightData) {
			case (nil, nil):
				return 0
			case (nil, _):
				return -1
			case (_, nil):
				return 1
			default:
				let leftSize = lhs.RAW_size
				let rightSize = rhs.RAW_size
				if (leftSize < rightSize) {
					return -1
				} else if (leftSize > rightSize) {
					return 1
				} else {
					return memcmp(lhs.RAW_data!, rhs.RAW_data!, Int(leftSize))
				}
		}
	}
}