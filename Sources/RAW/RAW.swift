// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
public typealias size_t = CRAW.size_t

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

import CRAW

public let RAW_memset = CRAW.memset
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
public struct RAW_byte:Sendable, Hashable, Comparable, Equatable, Codable {}

// MARK: Random Bytes
public func generateRandomBytes(count:Int) throws -> [UInt8] {
	struct GenerateRandomBytesError:Swift.Error {}
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
/// - parameter S: the type of the static buffer to generate and return
/// - returns: a static buffer of random bytes
/// - throws: InvalidSecureRandomBytesLengthError if the requested number of bytes is greater than 256
public func generateSecureRandomBytes<S>(as _:S.Type) throws -> S where S:RAW_staticbuff {
	return S(RAW_staticbuff:try generateSecureRandomBytes(count:MemoryLayout<S>.size))
}

/// source of secure random bytes from the system. this is the most secure way to generate random bytes, and is limited to a maximum 256 bytes.
/// - parameter [UInt8].Type: the type of the static buffer to generate and return
/// - parameter count: the number of bytes to generate
/// - returns: the byte array of bytes sourced
public func generateSecureRandomBytes(count:size_t) throws -> [UInt8] {
	guard count <= 256 else {
		throw InvalidSecureRandomBytesLengthError()
	}
	return try [UInt8](unsafeUninitializedCapacity:Int(count), initializingWith: { buffer, initializedCount in
		guard __craw_get_entropy_bytes(buffer.baseAddress, count) == 0 else {
			throw InvalidSecureRandomBytesLengthError()
		}
		initializedCount = Int(count)
	})
}

/// applies zeros to the specified memory region. after writing the zeros, the process will read the bytes back to ensure they were zeroed as expected.
public func secureZeroBytes(_ bytes:UnsafeMutableRawPointer, count:size_t) {
	__craw_secure_zero_bytes(bytes, count)
	guard __craw_assert_secure_zero_bytes(bytes, count) == 0 else {
		fatalError("memory assignment failure \(#file):\(#line)")
	}
}

/// applies zeros to the specified memory region. after writing the zeros, the process will read the bytes back to ensure they were zeroed as expected.
public func secureZeroBytes(_ buffer:UnsafeMutableRawBufferPointer) {
	__craw_secure_zero_bytes(buffer.baseAddress, buffer.count)
	guard __craw_assert_secure_zero_bytes(buffer.baseAddress, buffer.count) == 0 else {
		fatalError("memory assignment failure \(#file):\(#line)")
	}
}

/// applies zeros to the specified memory region. after writing the zeros, the process will read the bytes back to ensure they were zeroed as expected.
public func secureZeroBytes(_ buffer:UnsafeMutableBufferPointer<UInt8>) {
	__craw_secure_zero_bytes(buffer.baseAddress, buffer.count)
	guard __craw_assert_secure_zero_bytes(buffer.baseAddress, buffer.count) == 0 else {
		fatalError("memory assignment failure \(#file):\(#line)")
	}
}

public struct RAW_staticbuff_iterator<S>:IteratorProtocol where S:RAW_staticbuff {
	public typealias Element = UInt8
	private var index:Int = 0
	private let buffer:S
	
	public init(_ buffer:S) {
		self.buffer = buffer
	}
	
	public mutating func next() -> Element? {
		guard index < MemoryLayout<S.RAW_staticbuff_storetype>.size else {
			return nil
		}
		defer {
			index += 1
		}
		return buffer.RAW_access { rawBuffer in
			return rawBuffer[index]
		}
	}
}

extension RAW_staticbuff where Self:Sequence {
	public func makeIterator() -> RAW_staticbuff_iterator<Self> {
		return RAW_staticbuff_iterator(self)
	}
}