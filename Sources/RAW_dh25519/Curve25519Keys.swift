import __crawdog_curve25519
import RAW

/// represents a public key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct PublicKey:Sendable {
	/// generates a public key from a private key
	public init(_ privateKey:borrowing PrivateKey) {
		var newPublicKey = PublicKey(RAW_staticbuff:(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
		privateKey.RAW_access_staticbuff({ privateKeyPtr in
			newPublicKey.RAW_access_staticbuff_mutating({ publicKeyPtr in
				__crawdog_curve25519_calculate_public_key(publicKeyPtr, privateKeyPtr)
			})
		})
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
		self = randomSource
	}
}

/// represents a shared key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct SharedKey:Sendable {}