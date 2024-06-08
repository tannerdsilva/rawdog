import __crawdog_curve25519
import RAW

/// represents a public key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct PublicKey:Sendable {}

/// represents a private key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct PrivateKey:Sendable {}

/// represents a shared key in the curve25519 key exchange
@RAW_staticbuff(bytes:32)
public struct SharedKey:Sendable {}