// written by tanner silva in 2023.
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


extension RAW_val {
	/// returns a ``RAW_val`` that represents a "null value". the returned data size is zero, and the data pointer is nil.
	public static func nullValue() -> RAW_val {
		return RAW_val(mv_size:0, mv_data:nil)
	}
}

extension RAW_val:Hashable, Equatable {
	public func hash(into hasher:inout Hasher) {
		hasher.combine(bytes:UnsafeRawBufferPointer(start:self.mv_data, count:self.mv_size))
	}
	
	public static func == (lhs: RAW_val, rhs: RAW_val) -> Bool {
		if (lhs.mv_size == rhs.mv_size) {
			return memcmp(lhs.mv_data, rhs.mv_data, lhs.mv_size) == 0
		} else {
			return false
		}
	}
}

extension Array:RAW_encodable where Element == UInt8 {
	public func asRAW_val<R>(_ valFunc:(inout RAW_val) throws -> R) rethrows -> R {
		let getThing = try self.withContiguousStorageIfAvailable { someBytes in
			var val = RAW_val(mv_size:someBytes.count, mv_data:UnsafeMutableRawPointer(mutating:someBytes.baseAddress))
			return try valFunc(&val)
		}
		return getThing!
	}
}

extension RAW_val:Sequence {
	public struct Iterator:IteratorProtocol {
		public typealias Element = UInt8
		private let memory:UnsafeMutablePointer<UInt8>
		private var size:size_t
		private var i:size_t = 0
		init(_ val:RAW_val) {
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
	public typealias Element = UInt8
	public func makeIterator() -> Iterator {
		return Iterator(self)
	}
}