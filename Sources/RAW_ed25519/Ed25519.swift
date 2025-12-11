import __crawdog_curve25519
import RAW_dh25519
import RAW

extension MemoryGuarded where GuardedStaticbuffType == Ed25519.PrivateKey { }

public struct Ed25519 {
	/// represents a private key in the ed25519 key exchange
	@RAW_staticbuff(bytes:64)
	public struct PrivateKey:Sendable, Hashable, Comparable, Equatable {}

	@RAW_staticbuff(bytes:32)
	fileprivate struct SecretKey:Sendable, Hashable, Comparable, Equatable {}
	
	public static func generateKeys() throws -> (PublicKey, MemoryGuarded<Ed25519.PrivateKey>) {
		var publicKey = PublicKey(RAW_staticbuff: PublicKey.RAW_staticbuff_zeroed())
		var privateKey = try MemoryGuarded<Ed25519.PrivateKey>.blank()
		let sk = try generateSecureRandomBytes(as: Ed25519.SecretKey.self)
		publicKey.RAW_access_mutating { publicKeyPtr in
			privateKey.RAW_access_mutating { privateKeyPtr in
				sk.RAW_access { skPtr in
					
					__crawdog_ed25519_create_keypair(publicKeyPtr.baseAddress!, privateKeyPtr.baseAddress!, nil, skPtr.baseAddress!)
				}
			}
		}
		return (publicKey, privateKey)
	}
		
	public static func sign(signature:UnsafeMutablePointer<UInt8>, privateKey: MemoryGuarded<PrivateKey>, message: UnsafeBufferPointer<UInt8>) {
		privateKey.RAW_access { privateKeyPtr in
			__crawdog_ed25519_sign_message(signature, privateKeyPtr.baseAddress!, nil, message.baseAddress!, message.count)
		}
	}
	
	public static func verify(signature: UnsafeRawPointer, publicKey: PublicKey, message: UnsafeBufferPointer<UInt8>) -> Bool {
		publicKey.RAW_access { publicKeyPtr in
			return 0 != __crawdog_ed25519_verify_signature(signature, publicKeyPtr.baseAddress!, message.baseAddress!, message.count)
		}
	}
}
