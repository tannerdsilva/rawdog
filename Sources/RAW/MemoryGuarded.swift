// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import CRAW

public final class MemoryGuarded<GuardedStaticbuffType>:@unchecked Sendable, RAW_decodable, RAW_accessible_immutable, RAW_accessible_mutable where GuardedStaticbuffType:RAW_staticbuff {
	public struct MemoryPageLockFailure:Swift.Error {}

	private static func memoryPrepare() throws -> UnsafeMutableRawPointer {
		var storePtr:UnsafeMutableRawPointer? = nil
		
		#if os(Linux)
		guard posix_memalign(&storePtr, RAW_sysconf(Int32(_SC_PAGESIZE)), MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		#else
		guard posix_memalign(&storePtr, RAW_sysconf(_SC_PAGESIZE), MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		#endif

		guard RAW_mlock(storePtr, MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		try secureZeroBytes(storePtr!, count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		return storePtr!
	}

	private let storage:UnsafeMutableRawPointer

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

	public static func blank() throws -> MemoryGuarded {
		let storage = try Self.memoryPrepare()
		return MemoryGuarded(storage:storage)
	}
	
	public func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
		try body(UnsafeRawBufferPointer(start:storage.assumingMemoryBound(to:UInt8.self), count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size))
	}

	public func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
		try body(UnsafeMutableRawBufferPointer(start:storage.assumingMemoryBound(to:UInt8.self), count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size))
	}

	deinit {
		try? secureZeroBytes(storage, count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		_ = RAW_munlock(storage, MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		RAW_free(storage)
	}
}
