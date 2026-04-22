import __crawdog_dilithium
import RAW

// Dilithium2 : 2420
// Dilithium3 : 3293
// Dilithium5 : 4595
@RAW_staticbuff(bytes: 2420)
public struct Signature: Sendable, Hashable, Comparable, Equatable {}

// Dilithium2 : 1312
// Dilithium3 : 1952
// Dilithium5 : 2592
@RAW_staticbuff(bytes: 1312)
public struct PublicKey: Sendable, Hashable, Comparable, Equatable {}

// Dilithium2 : 2528
// Dilithium3 : 4000
// Dilithium5 : 4864
@RAW_staticbuff(bytes: 2528)
public struct PrivateKey: Sendable, Hashable, Comparable, Equatable {}

public func generateDilithiumKeyPair() throws -> (publicKey: PublicKey, privateKey: MemoryGuarded<PrivateKey>) {
	let privKeyBuff = try MemoryGuarded<PrivateKey>.blank()
	var pubKeyBuff = PublicKey(RAW_staticbuff: PublicKey.RAW_staticbuff_zeroed())
	_ = privKeyBuff.RAW_access_mutating { skPtr in
		pubKeyBuff.RAW_access_mutating { pkPtr in
			__crawdog_pqcrystals_dilithium2_ref_keypair(pkPtr.baseAddress!, skPtr.baseAddress!)
		}
	}
	return (publicKey: pubKeyBuff, privateKey: privKeyBuff)
}

public struct BlindingContext:~Copyable {
	
	/// the pointer that will be used to reference the blinding context for the cryptographic functions.
	internal let storage:UnsafeBufferPointer<UInt8>
	
	/// initialize a new blinding context for dilithium operations from a specified source of entropy data.
	/// - parameters:
	///		- randomSource: a secure random source of data. Must be less than 256 bytes long. Initializer will only take up to the first 255 bytes from random source.
	public init(context:UnsafeBufferPointer<UInt8>) {
		storage = context
	}
	
	public borrowing func sign(to signature:UnsafeMutablePointer<UInt8>, privateKey:MemoryGuarded<PrivateKey>, message:UnsafeBufferPointer<UInt8>) {
		var sigCount = MemoryLayout<Signature>.size
		_ = privateKey.RAW_access { privateKeyPtr in
			__crawdog_pqcrystals_dilithium2_ref_signature(signature, &sigCount, message.baseAddress!, message.count, storage.baseAddress!, storage.count, privateKeyPtr.baseAddress!)
		}
	}
	
	public borrowing func sign(privateKey:MemoryGuarded<PrivateKey>, message:UnsafeBufferPointer<UInt8>) -> Signature {
		var signature = Signature(RAW_staticbuff: Signature.RAW_staticbuff_zeroed())
		var sigCount = MemoryLayout<Signature>.size
		_ = signature.RAW_access_mutating { sigPtr in
			privateKey.RAW_access { privateKeyPtr in
				__crawdog_pqcrystals_dilithium2_ref_signature(sigPtr.baseAddress!, &sigCount, message.baseAddress!, message.count, storage.baseAddress!, storage.count, privateKeyPtr.baseAddress!)
			}
		}
		return signature
	}
}

/// a reusable context that can be used to efficiently verify large quantities of messages.
public struct VerificationContext:~Copyable {
	
	/// the pointer that will be used to reference the blinding context for the cryptographic functions.
	internal let storage:UnsafeBufferPointer<UInt8>
	
	/// initialize a new blinding context for dilithium operations from a specified source of entropy data.
	/// - parameters:
	///		- randomSource: a secure random source of data. Must be less than 256 bytes long. Initializer will only take up to the first 255 bytes from random source.
	public init(context:UnsafeBufferPointer<UInt8>) {
		storage = context
	}
	
	/// verifies the specified signature with the specified message content.
	///	- parameters:
	///		- signature: an unsafe buffer pointer to the bytes containing the signature data
	///		- message: an unsafe buffer pointer to the bytes containing the message data
	///		- publicKey: The public key of the user who signed the data.
	///	- returns: `true` is returned if the signature is valid.
	public borrowing func verify(signature:UnsafeBufferPointer<UInt8>, message:UnsafeBufferPointer<UInt8>, publicKey: PublicKey) -> Bool {
		publicKey.RAW_access { pkPtr in
			return __crawdog_pqcrystals_dilithium2_ref_verify(signature.baseAddress!, signature.count, message.baseAddress!, message.count, storage.baseAddress!, storage.count, pkPtr.baseAddress!) == 0
		}
	}
	
	/// verifies the specified signature with the specified message content.
	///	- parameters:
	///		- signature: A Signature of the message
	///		- message: an unsafe buffer pointer to the bytes containing the message data
	///		- publicKey: The public key of the user who signed the data.
	///	- returns: `true` is returned if the signature is valid.
	public borrowing func verify(signature:Signature, message:UnsafeBufferPointer<UInt8>, publicKey: PublicKey) -> Bool {
		signature.RAW_access { signaturePtr in
			publicKey.RAW_access { pkPtr in
				return __crawdog_pqcrystals_dilithium2_ref_verify(signaturePtr.baseAddress!, signaturePtr.count, message.baseAddress!, message.count, storage.baseAddress!, storage.count, pkPtr.baseAddress!) == 0
			}
		}
	}
}
