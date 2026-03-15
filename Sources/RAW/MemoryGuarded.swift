import CRAW

public final class MemoryGuarded<GuardedStaticbuffType>:@unchecked Sendable, RAW_decodable, RAW_accessible where GuardedStaticbuffType:RAW_staticbuff {
	public borrowing func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
		try body(UnsafeMutableRawBufferPointer(start:storage, count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size))
	}

    public borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
        try body(UnsafeRawBufferPointer(start:storage, count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size))
    }

	public init?(RAW_decode buff:UnsafeRawBufferPointer) {
		#if DEBUG
		assert(buff.count == MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size, "the provided buffer must be the same size as the RAW_fixed_type of the RAW_staticbuff type you are trying to decode into.")
		#endif
		do {
			storage = try Self.memoryPrepare()
		} catch {
			return nil
		}
		_ = RAW_memcpy(storage, buff.baseAddress!, buff.count)
	}

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
	private init(storage:UnsafeMutableRawPointer) {
		self.storage = storage
	}

	public static func blank() throws -> MemoryGuarded {
		let storage = try Self.memoryPrepare()
		return MemoryGuarded(storage:storage)
	}

	deinit {
		try? secureZeroBytes(storage, count:MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		_ = RAW_munlock(storage, MemoryLayout<GuardedStaticbuffType.RAW_fixed_type>.size)
		RAW_free(storage)
	}
}
