// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_crypt_blowfish
import func RAW.generateSecureRandomBytes
import CRAW

public enum Error:Swift.Error {
	case invalidMethod
	case phraseTooLong
	case noMemory
	case notSupported
	case unknown(Int)
}
public func generateSalt(passes:UInt = 12) throws -> [UInt8] {
	let saltCount = 256
	let newSaltBuffer = __crawdog_crypt_gensalt_ra("$2b$", passes, try! generateSecureRandomBytes(count:saltCount), Int32(saltCount))
	guard newSaltBuffer != nil else {
		let getErrno = __craw_get_system_errno()
		switch getErrno {
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
				throw Error.unknown(Int(getErrno))
		}
	}
	defer {
		free(newSaltBuffer!)
	}
	return [UInt8](RAW_decode:newSaltBuffer!, count:saltCount)
}
public func hash(phrase:consuming String, salt:borrowing [UInt8]) throws -> [UInt8] {
	var count:Int32 = 0
	return try salt.RAW_access { saltBuffer in
		var dataBuffer:UnsafeMutableRawPointer? = nil
		let newHashBuffer = __crawdog_crypt_ra(phrase, saltBuffer.baseAddress, &dataBuffer, &count)
		guard newHashBuffer != nil else {
			let getErrno = __craw_get_system_errno()
			switch getErrno {
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
					throw Error.unknown(Int(getErrno))
			}
		}
		defer {
			free(newHashBuffer!)
		}
		return [UInt8](RAW_decode:dataBuffer!, count:Int(count))
	}
}