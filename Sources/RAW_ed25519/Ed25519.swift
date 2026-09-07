import __crawdog_curve25519
import RAW_dh25519
import RAW

/// represents a private key in the ed25519 key exchange
@RAW_staticbuff(bytes:64)
public struct PrivateKey:Sendable, Hashable, Comparable, Equatable {}

/// a blinding context that can be used to harden ed25519 signature operations.
public struct BlindingContext:~Copyable {
	
	/// the pointer that will be used to reference the blinding context for the cryptographic functions.
	internal let storage:UnsafeMutableRawPointer
	
	/// initialize a new blinding context for ed25519 operations from a specified source of entropy data.
	/// - parameters:
	///		- randomSource: a secure random source of data.
	public init(randomSource:UnsafeBufferPointer<UInt8>) {
		storage = __crawdog_ed25519_blinding_init(nil, randomSource.baseAddress!, randomSource.count)
	}
	
	/// generate the private and public key pair that will be used for signing.
	///	- parameters:
	///		- secretKey: the dh25519 private key that should be used to create the
	public borrowing func generateKeys(secretKey:MemoryGuarded<RAW_dh25519.PrivateKey>) throws -> (PublicKey, MemoryGuarded<PrivateKey>) {
		var publicKey = PublicKey.RAW_comparable_fixed_theoretical_min()
		let privateKey = try MemoryGuarded<PrivateKey>.blank()
		publicKey.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { publicKeyPtr in
			privateKey.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { privateKeyPtr in
				secretKey.RAW_access_immutable(UnsafeRawBufferPointer.self) { skPtr in
					__crawdog_ed25519_create_keypair(publicKeyPtr.baseAddress!, privateKeyPtr.baseAddress!, storage, skPtr.baseAddress!)
				}
			}
		}
		return (publicKey, privateKey)
	}
	
	/// generate a message signature.
	///	- parameters:
	///		- signature: the destination buffer that will receive the signature (must hold at least 64 bytes)
	///		- privateKey: the ed25519 private key that should be used to sign
	///		- message: the message content that will be signed
	public borrowing func sign(to signature:UnsafeMutableBufferPointer<UInt8>, privateKey:MemoryGuarded<PrivateKey>, message:UnsafeBufferPointer<UInt8>) {
		precondition(signature.count >= 64, "ed25519 signature output must hold at least 64 bytes")
		privateKey.RAW_access_immutable(UnsafeRawBufferPointer.self) { privateKeyPtr in
			__crawdog_ed25519_sign_message(signature.baseAddress!, privateKeyPtr.baseAddress!, storage, message.baseAddress!, message.count)
		}
	}
	
	/// deinitialize the blinding context memory when this struct is dereferenced
	deinit {
		__crawdog_ed25519_blinding_finish(storage)
	}
}

/// a reusable context that can be used to efficiently verify large quantities of messages.
public struct VerificationContext:~Copyable {
	
	/// the pointer that will be used to reference the verification context for the cryptographic functions.
	internal let storage:UnsafeMutableRawPointer
	
	/// initialize a verification context from a specified public key.
	public init(publicKey:borrowing PublicKey) {
		storage = publicKey.RAW_access_immutable(UnsafeRawBufferPointer.self) { publicKeyPointer in
			return __crawdog_ed25519_verify_init(nil, publicKeyPointer.baseAddress!)
		}
	}
	
	/// verifies the specified signature with the specified message content.
	///	- parameters:
	///		- signature: the bytes containing the signature data (must be exactly 64 bytes)
	///		- message: an unsafe buffer pointer to the bytes containing the message data
	///	- returns: `true` is returned if the signature is valid.
	public borrowing func verify(signature:UnsafeBufferPointer<UInt8>, message:UnsafeBufferPointer<UInt8>) -> Bool {
		precondition(signature.count == 64, "ed25519 signature input must be exactly 64 bytes")
		return (__crawdog_ed25519_verify_check(storage, signature.baseAddress!, message.baseAddress!, message.count) == 1)
	}
	
	deinit {
		__crawdog_ed25519_verify_finish(storage)
	}
}

/// generate the private and public key pair that will be used for signing.
public func generateKeys(secretKey:MemoryGuarded<RAW_dh25519.PrivateKey>) throws -> (PublicKey, MemoryGuarded<PrivateKey>) {
	var publicKey = PublicKey.RAW_comparable_fixed_theoretical_min()
	let privateKey = try MemoryGuarded<PrivateKey>.blank()
	publicKey.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { publicKeyPtr in
		privateKey.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { privateKeyPtr in
			secretKey.RAW_access_immutable(UnsafeRawBufferPointer.self) { skPtr in
				__crawdog_ed25519_create_keypair(publicKeyPtr.baseAddress!, privateKeyPtr.baseAddress!, nil, skPtr.baseAddress!)
			}
		}
	}
	return (publicKey, privateKey)
}

/// generate a message signature.
public func sign(to signature:UnsafeMutableBufferPointer<UInt8>, privateKey:MemoryGuarded<PrivateKey>, message:UnsafeBufferPointer<UInt8>) {
	precondition(signature.count >= 64, "ed25519 signature output must hold at least 64 bytes")
	privateKey.RAW_access_immutable(UnsafeRawBufferPointer.self) { privateKeyPtr in
		__crawdog_ed25519_sign_message(signature.baseAddress!, privateKeyPtr.baseAddress!, nil, message.baseAddress!, message.count)
	}
}

/// verifies a message signature with a specified public key.
public func verify(signature:UnsafeBufferPointer<UInt8>, publicKey:borrowing PublicKey, message:UnsafeBufferPointer<UInt8>) -> Bool {
	precondition(signature.count == 64, "ed25519 signature input must be exactly 64 bytes")
	return publicKey.RAW_access_immutable(UnsafeRawBufferPointer.self) { publicKeyPtr in
		return (0 != __crawdog_ed25519_verify_signature(signature.baseAddress!, publicKeyPtr.baseAddress!, message.baseAddress!, message.count))
	}
}
