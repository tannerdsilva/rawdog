import __crawdog_curve25519
import RAW_dh25519
import RAW

/// represents a private key in the ed25519 key exchange
@RAW_staticbuff(bytes:64)
public struct PrivateKey:Sendable, Hashable, Comparable, Equatable {}
	
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
		
//	public static func sign(signature:UnsafeMutablePointer<UInt8>, privateKey: MemoryGuarded<PrivateKey>, message: UnsafeBufferPointer<UInt8>) {
//		privateKey.RAW_access { privateKeyPtr in
//			__crawdog_ed25519_sign_message(signature, privateKeyPtr.baseAddress!, nil, message.baseAddress!, message.count)
//		}
//	}
//	
//	public static func verify(signature: UnsafeRawPointer, publicKey: PublicKey, message: UnsafeBufferPointer<UInt8>) -> Bool {
//		publicKey.RAW_access { publicKeyPtr in
//			return 0 != __crawdog_ed25519_verify_signature(signature, publicKeyPtr.baseAddress!, message.baseAddress!, message.count)
//		}
//	}