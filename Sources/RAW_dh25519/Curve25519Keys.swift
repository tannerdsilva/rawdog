import __crawdog_curve25519
import RAW

/// represents a public key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct PublicKey:Sendable, Hashable, Comparable, Equatable {
	/// generates a public key from a private key
	public init(privateKey:UnsafePointer<PrivateKey>) {
		var newPublicKey = PublicKey.RAW_comparable_fixed_theoretical_min()
		newPublicKey.RAW_access_mutable(UnsafeMutableRawBufferPointer.self, { publicKeyPtr in
			__crawdog_curve25519_calculate_public_key(publicKeyPtr.baseAddress!, privateKey)
		})
		self = newPublicKey
	}
	public init(privateKey:MemoryGuarded<PrivateKey>) {
		self = PublicKey.RAW_comparable_fixed_theoretical_min()
		RAW_access_mutable(UnsafeMutableRawBufferPointer.self, { publicKeyPtr in
			privateKey.RAW_access_immutable(UnsafeRawBufferPointer.self, { pkBuff in
				__crawdog_curve25519_calculate_public_key(publicKeyPtr.baseAddress!, pkBuff.baseAddress)
			})
		})
	}
}

/// represents a private key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct PrivateKey:Sendable, Hashable, Comparable, Equatable {}

extension MemoryGuarded where GuardedStaticbuffType == PrivateKey {
	/// generates a private key in a cryptographically secure manner
	public static func new() throws -> MemoryGuarded<PrivateKey> {
		let newBuff = try MemoryGuarded<PrivateKey>.blank()
		try generateSecureRandomBytes(count:MemoryLayout<PrivateKey.RAW_fixed_type>.size).withUnsafeBytes { buf in
			newBuff.RAW_access_mutable(UnsafeMutableRawBufferPointer.self, { privateKeyPtr in
				privateKeyPtr.copyMemory(from:buf)
				__crawdog_curve25519_forge_private_key(privateKeyPtr.baseAddress!)
			})
		}
		return newBuff
	}
}

/// represents a shared key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct SharedKey:Sendable, Hashable, Comparable, Equatable {}

extension MemoryGuarded where GuardedStaticbuffType == SharedKey {
	/// computes a shared key from a private key and a public key
	public static func compute(privateKey:MemoryGuarded<PrivateKey>, publicKey:PublicKey) throws -> MemoryGuarded<SharedKey> {
		try publicKey.RAW_access_immutable(UnsafeRawBufferPointer.self, { pubBuff in
			try privateKey.RAW_access_immutable(UnsafeRawBufferPointer.self, { pkBuff in
				let newBuff = try MemoryGuarded<SharedKey>.blank()
				newBuff.RAW_access_mutable(UnsafeMutableRawBufferPointer.self, { sharedKeyPtr in
					__crawdog_curve25519_calculate_shared_key(sharedKeyPtr.baseAddress!, pubBuff.baseAddress, pkBuff.baseAddress)
				})
				return newBuff
			})
		})
	}
}
