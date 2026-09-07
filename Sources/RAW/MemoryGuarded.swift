// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import CRAW

/// a memory-pinned wrapper around a ``RAW_staticbuff`` type. instances are backed by a
/// page-aligned allocation that is locked with `mlock` and securely zeroed on release,
/// protecting the raw bytes from being swapped to disk or left behind in freed memory.
///
/// use ``MemoryGuarded/blank()`` to create a zeroed, locked instance, or decode an
/// existing value directly with `init?(RAW_decode:)`.
public final class MemoryGuarded<GuardedStaticbuffType>:@unchecked Sendable, RAW_decodable, RAW_accessible_immutable, RAW_accessible_mutable where GuardedStaticbuffType:RAW_staticbuff {
	/// thrown when a page-aligned allocation, memory lock, or secure zeroing fails.
	public struct MemoryPageLockFailure:Swift.Error {}

	private static func memoryPrepare() throws -> UnsafeMutableRawPointer {
		var storePtr:UnsafeMutableRawPointer? = nil
		
		#if os(Linux)
		guard posix_memalign(&storePtr, CRAW.sysconf(Int32(_SC_PAGESIZE)), MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		#else
		guard posix_memalign(&storePtr, CRAW.sysconf(_SC_PAGESIZE), MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		#endif

		guard CRAW.mlock(storePtr, MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		try secureZeroBytes(storePtr!, count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		return storePtr!
	}

	private let storage:UnsafeMutableRawPointer

	/// decodes the raw bytes of `buff` into a freshly locked allocation. returns nil
	/// unless `buff.count` exactly matches the wrapped type's fixed size.
	public init?(RAW_decode buff:UnsafeRawBufferPointer) {
		guard buff.count == MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size else {
			return nil
		}
		do {
			storage = try Self.memoryPrepare()
			_ = RAW_memcpy(storage, buff.baseAddress, buff.count)
		} catch {
			return nil
		}
	}

	private init(storage:UnsafeMutableRawPointer) {
		self.storage = storage
	}

	/// creates a new locked, zeroed instance without any decoded content.
	/// - throws: a ``MemoryGuarded/MemoryPageLockFailure`` if the page-aligned
	///   allocation, memory lock, or secure zeroing fails.
	public static func blank() throws -> MemoryGuarded {
		let storage = try Self.memoryPrepare()
		return MemoryGuarded(storage:storage)
	}
	
	/// immutable access to the locked storage bytes.
	public func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
		try body(UnsafeRawBufferPointer(start:storage.assumingMemoryBound(to:UInt8.self), count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size))
	}

	/// mutable access to the locked storage bytes.
	public func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
		try body(UnsafeMutableRawBufferPointer(start:storage.assumingMemoryBound(to:UInt8.self), count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size))
	}

	deinit {
		try? secureZeroBytes(storage, count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		_ = CRAW.munlock(storage, MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		CRAW.free(storage)
	}
}
