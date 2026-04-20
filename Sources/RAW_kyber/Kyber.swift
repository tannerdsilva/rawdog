import __crawdog_kyber
import RAW

@RAW_staticbuff(bytes: 32)
public struct SharedSecret: Sendable, Hashable, Comparable, Equatable {}

// k = 2 : 768
// k = 3 : 1088
// k = 4 : 1568
@RAW_staticbuff(bytes: 1088)
public struct Ciphertext: Sendable, Hashable, Comparable, Equatable {}

// k = 2 : 800
// k = 3 : 1184
// k = 4 : 1568
@RAW_staticbuff(bytes: 1184)
public struct PublicKey: Sendable, Hashable, Comparable, Equatable {}

// k = 2 : 1632
// k = 3 : 2400
// k = 4 : 3168
@RAW_staticbuff(bytes: 2400)
public struct PrivateKey: Sendable, Hashable, Comparable, Equatable {}

public func generateKyberKeyPair() throws -> (publicKey: PublicKey, privateKey: MemoryGuarded<PrivateKey>) {
	let privKeyBuff = try MemoryGuarded<PrivateKey>.blank()
	var pubKeyBuff = PublicKey(RAW_staticbuff: PublicKey.RAW_staticbuff_zeroed())
	_ = privKeyBuff.RAW_access_mutating { skPtr in
		pubKeyBuff.RAW_access_mutating { pkPtr in
			__crawdog_pqcrystals_kyber768_ref_keypair(pkPtr.baseAddress!, skPtr.baseAddress!)
		}
	}
	return (publicKey: pubKeyBuff, privateKey: privKeyBuff)
}

public func kyberEncapsulation(publicKey: PublicKey) -> (Ciphertext, SharedSecret) {
	var cipherText = Ciphertext(RAW_staticbuff: Ciphertext.RAW_staticbuff_zeroed())
	var sharedSecret = SharedSecret(RAW_staticbuff: SharedSecret.RAW_staticbuff_zeroed())
	
	_ = publicKey.RAW_access { pkPtr in
		cipherText.RAW_access_mutating { ccPtr in
			sharedSecret.RAW_access_mutating { ssPtr in
				__crawdog_pqcrystals_kyber768_ref_enc(ccPtr.baseAddress!, ssPtr.baseAddress!, pkPtr.baseAddress!)
			}
		}
	}
	
	return (cipherText: cipherText, sharedSecret: sharedSecret)
}

public func kyberDecapsulation(cipherText: Ciphertext, privateKey: MemoryGuarded<PrivateKey>) -> SharedSecret {
	var sharedSecret = SharedSecret(RAW_staticbuff: SharedSecret.RAW_staticbuff_zeroed())
	
	_ = privateKey.RAW_access { skPtr in
		cipherText.RAW_access { ccPtr in
			sharedSecret.RAW_access_mutating { ssPtr in
				__crawdog_pqcrystals_kyber768_ref_dec(ssPtr.baseAddress!, ccPtr.baseAddress!, skPtr.baseAddress!)
			}
		}
	}
	
	return sharedSecret
}
