import __crawdog_curve25519
import RAW

/// represents a public key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct PublicKey:Sendable {
	/// generates a public key from a private key
	public init(_ privateKey:UnsafePointer<PrivateKey>) {
		var newPublicKey = PublicKey(RAW_staticbuff:(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
		newPublicKey.RAW_access_staticbuff_mutating({ publicKeyPtr in
			__crawdog_curve25519_calculate_public_key(publicKeyPtr, privateKey)
		})
		defer {
			newPublicKey.RAW_access_staticbuff_mutating { publicKeyPtr in
				secureZeroBytes(publicKeyPtr, count:32)
			}
		}
		self = newPublicKey
	}
}

/// represents a private key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct PrivateKey:Sendable {
	/// generates a private key in a cryptographically secure manner
	public init() throws {
		var randomSource = try generateSecureRandomBytes(as:PrivateKey.self)
		__crawdog_curve25519_forge_private_key(&randomSource)
		defer {
			randomSource.RAW_access_staticbuff_mutating { privateKeyPtr in
				secureZeroBytes(privateKeyPtr, count:32)
			}
		}
		self = randomSource
	}
}

/// represents a shared key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct SharedKey:Sendable {
	public static func compute(privateKey:UnsafePointer<PrivateKey>, publicKey:UnsafePointer<PublicKey>) -> SharedKey {
		var newSharedKey = Self(RAW_staticbuff:(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
		__crawdog_curve25519_calculate_shared_key(&newSharedKey, publicKey, privateKey)
		defer {
			newSharedKey.RAW_access_staticbuff_mutating { sharedKeyPtr in
				secureZeroBytes(sharedKeyPtr, count:32)
			}
		}
		return newSharedKey
	}
}