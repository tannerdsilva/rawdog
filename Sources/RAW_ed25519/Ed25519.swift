import __crawdog_curve25519
import RAW_dh25519
import RAW

/// represents a private key in the ed25519 key exchange
@RAW_staticbuff(bytes:64)
public struct PrivateKey:Sendable, Hashable, Comparable, Equatable {}

/// a blinding context that can be used to harden ed25519 signature operations.
public struct BlindingContext:~Copyable {
	/// the pointer that will be used to reference the blinding context for the cryptographic functions.
	private var storage:UnsafeMutableRawPointer? = nil
	
	/// initialize a new blinding context for ed25519 operations.
	public init() {
		
	}
	
	/// access the blinding context that is being contained within the structure instance.
	///	- parameters:
	///		- accessor: the accessor function that will be called and passed with the current memory position of the blinding context.
	///	- NOTE: values returned or thrown by the accessor function will be transparently returned (or re-thrown) through this function.
	public mutating func accessBlindingContext<R, E>(_ accessor:(inout UnsafeMutableRawPointer?) throws (E) -> R) throws(E) -> R {
		return try accessor(&storage)
	}
}

/// generate the private and public key pair that will be used for signing.
public func generateKeys(secretKey:MemoryGuarded<RAW_dh25519.PrivateKey>) throws -> (PublicKey, MemoryGuarded<PrivateKey>) {
	var publicKey = PublicKey(RAW_staticbuff:PublicKey.RAW_staticbuff_zeroed())
	let privateKey = try MemoryGuarded<PrivateKey>.blank()
	publicKey.RAW_access_mutating { publicKeyPtr in
		privateKey.RAW_access_mutating { privateKeyPtr in
			secretKey.RAW_access { skPtr in
				__crawdog_ed25519_create_keypair(publicKeyPtr.baseAddress!, privateKeyPtr.baseAddress!, nil, skPtr.baseAddress!)
			}
		}
	}
	return (publicKey, privateKey)
}

public func sign(to signature:UnsafeMutablePointer<UInt8>, privateKey:MemoryGuarded<PrivateKey>, message:UnsafeBufferPointer<UInt8>) {
	privateKey.RAW_access { privateKeyPtr in
		__crawdog_ed25519_sign_message(signature, privateKeyPtr.baseAddress!, nil, message.baseAddress!, message.count)
	}
}

public func verify(signature:UnsafePointer<UInt8>, publicKey:PublicKey, message:UnsafeBufferPointer<UInt8>) -> Bool {
	return publicKey.RAW_access { publicKeyPtr in
		return (0 != __crawdog_ed25519_verify_signature(signature, publicKeyPtr.baseAddress!, message.baseAddress!, message.count))
	}
}