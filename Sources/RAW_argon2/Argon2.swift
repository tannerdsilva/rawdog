// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_argon2
import RAW

/// represents an error that can occur when using Argon2
public enum Error:Int32, Swift.Error {
	case pointerNull = -1

	case outputTooShort = -2
	case outputTooLong = -3

	case pwdTooShort = -4
	case pwdTooLong = -5

	case saltTooShort = -6
	case saltTooLong = -7

	case adTooShort = -8
	case adTooLong = -9

	case secretTooShort = -10
	case secretTooLong = -11

	case timeTooSmall = -12
	case timeTooLarge = -13

	case memoryTooSmall = -14
	case memoryTooLarge = -15

	case lanesTooFew = -16
	case lanesTooMany = -17

	case pwdPtrMismatch = -18
	case saltPtrMismatch = -19
	case secretPtrMismatch = -20
	case adPtrMismatch = -21

	case memoryAllocationError = -22

	case freeMemoryCBKNull = -23
	case allocateMemoryCBKNull = -24

	case incorrectParameter = -25
	case incorrectType = -26

	case outPtrMismatch = -27

	case threadsTooFew = -28
	case threadsTooMany = -29

	case missingArgs = -30
	
	case encodingFail = -31

	case decodingFail = -32

	case threadFail = -33

	case decodingLengthFail = -34

	case verifyMismatch = -35
}

/// argon2_id implementation
public struct ID {
	/// produces an Argon2id hash with the specified parameters to the static-length output type
	/// - parameters:
	/// 	- password: the password to hash
	/// 	- salt: the salt to use for the hashing operation
	/// 	- timeCost: the number of iterations to perform
	/// 	- memoryCost: the amount of memory to use in kibibytes
	/// 	- parallelism: the number of threads to use
	/// - returns: the resulting output bytes directly applied to the output type
	public static func hash<P, S, O>(password:consuming P, salt:borrowing S, timeCost:UInt32, memoryCost:UInt32, parallelism:UInt32, as outputType:O.Type) throws -> O where O:RAW_staticbuff, P:RAW_accessible, S:RAW_accessible {
		let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity:MemoryLayout<O>.size)
		defer {
			tempBuffer.deallocate()
		}
		try salt.RAW_access { (saltPtr:UnsafeBufferPointer<UInt8>) in
			try password.RAW_access { (pwdPtr:UnsafeBufferPointer<UInt8>) in
				let res = __crawdog_argon2id_hash_raw(
					timeCost,
					memoryCost,
					parallelism,
					pwdPtr.baseAddress, pwdPtr.count,
					saltPtr.baseAddress, saltPtr.count,
					tempBuffer, MemoryLayout<O>.size
				)
				guard res == __CRAWDOG_ARGON2_OK.rawValue else {
					throw Error(rawValue:res)!
				}
			}
		}
		return O(RAW_staticbuff:tempBuffer)
	}
}