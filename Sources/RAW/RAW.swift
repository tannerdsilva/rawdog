// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

import CRAW

// MARK: - C function re-exports (deprecated, use CRAW directly)
@available(*, deprecated, message: "use CRAW.memcpy directly")
public let RAW_memset = CRAW.memset
@available(*, deprecated, message: "use CRAW.memcmp directly")
public let RAW_memcmp = CRAW.memcmp
@available(*, deprecated, message: "use CRAW.memcpy directly")
public let RAW_memcpy = CRAW.memcpy
@available(*, deprecated, message: "use CRAW.mlock directly")
public let RAW_mlock = CRAW.mlock
@available(*, deprecated, message: "use CRAW.munlock directly")
public let RAW_munlock = CRAW.munlock
@available(*, deprecated, message: "use CRAW.malloc directly")
public let RAW_malloc = CRAW.malloc
@available(*, deprecated, message: "use CRAW.free directly")
public let RAW_free = CRAW.free
@available(*, deprecated, message: "use CRAW.sysconf directly")
public let RAW_sysconf = CRAW.sysconf

@available(*, deprecated, message: "use CRAW.strlen directly")
public func RAW_strlen(_ str:UnsafeRawPointer) -> size_t {
	return CRAW.strlen(str)
}

// MARK: - Secure zeroing

/// the type of error that is thrown when a memory page could not be zeroed
public struct ByteZeroFailure:Swift.Error {}

/// applies zeros to the specified memory region. after writing the zeros, the process will read the bytes back to ensure they were zeroed as expected.
public func secureZeroBytes(_ bytes:UnsafeMutableRawPointer, count:size_t) throws {
	__craw_secure_zero_bytes(bytes, count)
	guard __craw_assert_secure_zero_bytes(bytes, count) == 0 else {
		throw ByteZeroFailure()
	}
}

/// applies zeros to the specified memory region. after writing the zeros, the process will read the bytes back to ensure they were zeroed as expected.
public func secureZeroBytes(_ buffer:UnsafeMutableRawBufferPointer) throws {
	__craw_secure_zero_bytes(buffer.baseAddress!, buffer.count)
	guard __craw_assert_secure_zero_bytes(buffer.baseAddress!, buffer.count) == 0 else {
		throw ByteZeroFailure()
	}
}

/// applies zeros to the specified memory region. after writing the zeros, the process will read the bytes back to ensure they were zeroed as expected.
public func secureZeroBytes(_ buffer:UnsafeMutableBufferPointer<UInt8>) throws {
	__craw_secure_zero_bytes(buffer.baseAddress!, buffer.count)
	guard __craw_assert_secure_zero_bytes(buffer.baseAddress!, buffer.count) == 0 else {
		throw ByteZeroFailure()
	}
}

// MARK: - Random bytes

/// the type of error that is thrown when random bytes could not be generated
public struct GenerateRandomBytesError:Swift.Error {}

public func generateRandomBytes(count:Int) throws -> [UInt8] {
	return try [UInt8](unsafeUninitializedCapacity:count) { buffer, initializedCount in
		buffer.initialize(repeating:0)
		let fd = open("/dev/urandom", O_RDONLY)
		guard fd > 0 else {
			throw GenerateRandomBytesError()
		}
		defer {
			close(fd)
		}
		let result = read(fd, buffer.baseAddress, count)
		guard result == count else {
			throw GenerateRandomBytesError()
		}
		initializedCount = count
	}
}

/// this error is thrown when the secure random bytes generator fails to generate the requested number of bytes
public struct InvalidSecureRandomBytesLengthError:Error {}

/// source of secure random bytes from the system. this is the most secure way to generate random bytes, and is limited to a maximum 256 bytes.
/// - parameter [UInt8].Type: the type of the static buffer to generate and return
/// - parameter count: the number of bytes to generate
/// - returns: the byte array of bytes sourced
public func generateSecureRandomBytes(count:size_t) throws -> [UInt8] {
	guard count <= 256 else {
		throw InvalidSecureRandomBytesLengthError()
	}
	return try [UInt8](unsafeUninitializedCapacity:Int(count), initializingWith: { buffer, initializedCount in
		guard __craw_get_entropy_bytes(buffer.baseAddress!, count) == 0 else {
			throw InvalidSecureRandomBytesLengthError()
		}
		initializedCount = Int(count)
	})
}

// MARK: - RAW_byte type

@RAW_staticbuff(bytes:1)
public struct RAW_byte:Sendable, RAW_native, Hashable, Comparable, Equatable, Codable, CustomDebugStringConvertible {
	#RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:false)
	public var debugDescription:String {
		return "\(RAW_native())"
	}
}
