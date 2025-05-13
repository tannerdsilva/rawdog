// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_crypt_blowfish
import CRAW
import RAW

public enum Error:Swift.Error {
	case invalidMethod
	case phraseTooLong
	case noMemory
	case notSupported
	case unknown(Int)
}

@RAW_staticbuff(bytes:256)
public struct Salt:Sendable {
	public static func generate(passes:UInt = 12) throws -> Self {
		let newSaltBuffer = __crawdog_crypt_gensalt_ra("$2b$", passes, try! generateSecureRandomBytes(count:MemoryLayout<Salt>.size), Int32(MemoryLayout<Salt>.size))
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
		return Salt(RAW_staticbuff:newSaltBuffer!)
	}
}

public func hash(phrase:borrowing String, salt:borrowing Salt) throws -> [UInt8] {
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