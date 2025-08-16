import CRAW

public final class MemoryGuarded<GuardedStaticbuffType>:@unchecked Sendable, RAW_decodable, RAW_accessible where GuardedStaticbuffType:RAW_staticbuff {
	public struct MemoryPageLockFailure:Swift.Error {}

	private static func memoryPrepare() throws -> UnsafeMutableRawPointer {
		var storePtr:UnsafeMutableRawPointer? = nil
		guard posix_memalign(&storePtr, RAW_sysconf(_SC_PAGESIZE), MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		guard RAW_mlock(storePtr, MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size) == 0 else {
			throw MemoryPageLockFailure()
		}
		try secureZeroBytes(storePtr!, count:MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size)
		return storePtr!
	}

	private let storage:UnsafeMutableRawPointer

	public init?(RAW_decode:UnsafeRawPointer, count:RAW.size_t) {
		guard count == MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size else {
			return nil
		}
		do {
			storage = try Self.memoryPrepare()
			_ = RAW_memcpy(storage, RAW_decode, count)
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
	
	public func RAW_access<R, E>(_ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		try body(UnsafeBufferPointer(start:storage.assumingMemoryBound(to:UInt8.self), count:MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size))
	}

	public func RAW_access_mutating<R, E>(_ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		try body(UnsafeMutableBufferPointer(start:storage.assumingMemoryBound(to:UInt8.self), count:MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size))
	}

	deinit {
		try? secureZeroBytes(storage, count:MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size)
		_ = RAW_munlock(storage, MemoryLayout<GuardedStaticbuffType.RAW_staticbuff_storetype>.size)
		RAW_free(storage)
	}
}
