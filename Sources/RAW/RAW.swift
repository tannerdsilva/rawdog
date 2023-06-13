// written by tanner silva in 2023 (c).
// rawdog is a swift library that makes it easy to encode and decode programming objects from C-like memory representations.
import CRAW

/// buffer representation struct
public typealias RAW_val = CRAW.RAW_val

/// convertible protocol that encapsulates encodable and decodable protocols
public typealias RAW_convertible = RAW_encodable & RAW_decodable

/// the protocol that enables initialization of programming objects from raw memory.
public protocol RAW_decodable {
	init?(_ value:RAW_val)
}

/// the protocol that enables encoding of programming objects to raw memory.
public protocol RAW_encodable {
	func asRAW_val<R>(_ valFunc:(inout RAW_val) throws -> R) rethrows -> R
}

/// the protocol that enables comparison of programming objects from raw memory representations.
public protocol RAW_comparable {
	typealias RAW_compare_function = @convention(c)(UnsafePointer<RAW_val>?, UnsafePointer<RAW_val>?) -> Int32 
	static var rawCompareFunction:RAW_compare_function { get }
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
	public func asRAW_val<R>(_ valFunc:(inout RAW_val) throws -> R) rethrows -> R {
		if let getThing = try self.withContiguousStorageIfAvailable({ someBytes in
			var val = RAW_val(mv_size:someBytes.count, mv_data:UnsafeMutableRawPointer(mutating:someBytes.baseAddress))
			return try valFunc(&val)
		}) {
			return getThing
		} else {
			let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: self.count)
			defer { buffer.deallocate() }
			_ = buffer.initialize(from: self)
			var val = RAW_val(mv_size:self.count, mv_data:buffer.baseAddress)
			return try valFunc(&val)
		}
	}
}

// Sequence conformance
extension RAW_val:Sequence {

	/// an object that strides through the contents of a RAW_val.
	public struct Iterator:IteratorProtocol {
		public typealias Element = UInt8
		private let memory:UnsafeMutablePointer<UInt8>
		private var size:size_t
		private var i:size_t = 0
		internal init(_ val:RAW_val) {
			self.memory = val.mv_data.assumingMemoryBound(to:UInt8.self)
			self.size = val.mv_size
		}
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