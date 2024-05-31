// written by tanner silva in 2023 (c) all rights reserved.

// rawdog is a swift library that makes it easy to encode and decode programming objects from C-like memory representations.

import struct CRAW.size_t
public typealias size_t = CRAW.size_t

import func CRAW.memcmp
import func CRAW.memcpy
import func CRAW.strlen

public let RAW_memcmp = CRAW.memcmp
public let RAW_memcpy = CRAW.memcpy
public func RAW_strlen(_ str:UnsafeRawPointer) -> size_t {
	return CRAW.strlen(str)
}

#if RAWDOG_LOG
import Logging
internal func makeDefaultLogger(label loggerLabel:String, level:Logger.Level) -> Logger {
	let logger = Logger(label:loggerLabel)
	logger.logLevel = .trace
	return logger
}
internal let mainLogger = Logger(label:"RAW")
#endif

@RAW_staticbuff(bytes:1)
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:false)
public struct RAW_byte:Sendable {}

// /// a default implementation of the ``RAW_val`` protocol.
// @frozen public struct val:RAW_val {
// 	/// the raw data that the structure instance represents.
// 	public let RAW_val_data_ptr:UnsafeRawPointer

// 	/// the size of the data that the structure instance represents.
// 	public let RAW_val_size:size_t

// 	/// creates a new RAW object from a given size and pointer.
// 	public init(RAW_val_size:size_t, RAW_val_data_ptr:UnsafeRawPointer) {
// 		self.RAW_val_data_ptr = RAW_val_data_ptr
// 		self.RAW_val_size = RAW_val_size

// 		#if RAWDOG_LOG
// 		mainLogger.trace("created val with size \(RAW_val_size) and data pointer \(RAW_val_data_ptr)")
// 		#endif
// 	}
// }

// // sequence conformance for RAW_val. allows for convenient iteration.
// extension val:Sequence {

// 	/// returns a new iterator that will stride the contents of the RAW_val.
// 	public func makeIterator() -> RAW_val_iterator {
// 		return RAW_val_iterator(self)
// 	}

// 	/// an object that strides through the contents of a RAW_val.
// 	public struct RAW_val_iterator:IteratorProtocol {
		
// 		/// the sequence element for this iterator is UInt8
// 		public typealias Element = UInt8

// 		// represents the memory (byte buffer) that this iterator is striding through.
// 		private let memory:UnsafeRawPointer
		
// 		// the size of the data that this iterator is striding through.
// 		private var size:size_t
		
// 		// the current index of the iterator.
// 		private var i:size_t = 0
		
// 		// creates a new iterator based on the memory contents of a given ``RAW_val``.
// 		internal init<R>(_ val:R) where R:RAW_val {
// 			self.memory = val.RAW_val_data_ptr
// 			self.size = val.RAW_val_size

// 			#if RAWDOG_LOG
// 			mainLogger.trace("created RAW_val_iterator with size \(size) and data pointer \(memory)")
// 			#endif
// 		}

// 		/// returns the next element in the sequence, or nil if there are no more elements.
// 		public mutating func next() -> Self.Element? {
// 			if (i >= size) {
// 				return nil
// 			} else {

// 				#if RAWDOG_LOG
// 				mainLogger.trace("RAW_val_iterator is returning element at index \(i)")
// 				#endif

// 				defer {
// 					i += 1;
// 				}
// 				return self.memory.advanced(by:i).load(as:UInt8.self)
// 			}
// 		}
// 	}
// }

// // collection conformances for RAW_val, allows for convenient random access.
// extension val:Collection {
// 	/// the start index for this collection is zero.
// 	public var startIndex:size_t {
// 		return 0
// 	}

// 	/// the end index for this collection is the size of the ``RAW_val``.
// 	public var endIndex:size_t {
// 		return self.RAW_val_size
// 	}

// 	/// returns the element at the given index.
// 	public subscript(position:size_t) -> UInt8 {
// 		return self.RAW_val_data_ptr.assumingMemoryBound(to:UInt8.self).advanced(by:position).pointee
// 	}

// 	/// returns the index after the given index.
// 	public func index(after i:size_t) -> size_t {
// 		return i + 1
// 	}
// }