// LICENSE MIT
// (c) tanner silva 2024. all rights reserved.
import ccrypt_blowfish
import func RAW.generateSecureRandomBytes
import CRAW

public enum Error:Swift.Error {
	case invalidMethod
	case phraseTooLong
	case noMemory
	case notSupported
	case unknown
}
public func makeSalt(passes:UInt = 12) throws -> [UInt8] {
	let randBytes = try! generateSecureRandomBytes(count:256)
	let newSaltBuffer = UnsafeMutableRawPointer(crypt_gensalt_ra("$2b$", passes, randBytes, 256))
	guard newSaltBuffer != nil else {
		switch __craw_get_system_errno() {
			case EINVAL:
				throw Error.invalidMethod
			case ERANGE:
				throw Error.phraseTooLong
			case ENOMEM:
				throw Error.noMemory
			case ENOSYS:
				throw Error.notSupported
			case EOPNOTSUPP:
				throw Error.notSupported
			default:
				throw Error.unknown
		}
	}
	defer {
		free(newSaltBuffer!)
	}
	return Array(UnsafeBufferPointer<UInt8>(start:newSaltBuffer!.assumingMemoryBound(to:UInt8.self), count:256))
}
public func hash(phrase:consuming String, salt:borrowing [UInt8]) throws -> [UInt8] {
	var count:Int32 = 0
	return try salt.RAW_access { saltBuffer in
		var dataBuffer:UnsafeMutableRawPointer? = nil
		let newHashBuffer = crypt_ra(phrase, saltBuffer.baseAddress, &dataBuffer, &count)
		guard newHashBuffer != nil else {
			switch __craw_get_system_errno() {
				case EINVAL:
					throw Error.invalidMethod
				case ERANGE:
					throw Error.phraseTooLong
				case ENOMEM:
					throw Error.noMemory
				case ENOSYS:
					throw Error.notSupported
				case EOPNOTSUPP:
					throw Error.notSupported
				default:
					throw Error.unknown
			}
		}
		defer {
			free(newHashBuffer!)
		}
		return Array(RAW_decode:dataBuffer!, count:Int(count))
	}
}