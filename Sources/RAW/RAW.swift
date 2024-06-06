// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import struct CRAW.size_t
public typealias size_t = CRAW.size_t

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

import CRAW

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

// MARK: Random Bytes
public func generateSecureRandomBytes(count:Int) throws -> [UInt8] {
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