// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

import CRAW

// MARK: - Secure zeroing

/// the type of error that is thrown when a memory page could not be zeroed
public struct ByteZeroFailure:Swift.Error {}

/// applies zeros to the specified memory region. after writing the zeros, the process will read the bytes back to ensure they were zeroed as expected.
public func secureZeroBytes(_ bytes:UnsafeMutableRawPointer, count:Int) throws {
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

/// this error is thrown when the secure random bytes generator fails to generate the requested number of bytes
public struct InvalidSecureRandomBytesLengthError:Error {}

/// source of secure random bytes from the system. this is the most secure way to generate random bytes, and is limited to a maximum 256 bytes.
/// - parameter [UInt8].Type: the type of the static buffer to generate and return
/// - parameter count: the number of bytes to generate
/// - returns: the byte array of bytes sourced
public func generateSecureRandomBytes(count:Int) throws -> [UInt8] {
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
@RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:false)
public struct RAW_byte:Sendable, RAW_native, Hashable, Comparable, Equatable, Codable, CustomDebugStringConvertible {
	public var debugDescription:String {
		return "\(RAW_native())"
	}
}
