// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_chachapoly
import RAW

@RAW_staticbuff(bytes:12)
public struct Nonce:Sendable, Equatable {}

// poly1305 tag is 16 bytes
@RAW_staticbuff(bytes:16)
public struct Tag:Sendable, Equatable {
	public init() {
		self = Self(RAW_staticbuff:Self.RAW_staticbuff_zeroed())
	}
}

public struct InvalidMACError:Swift.Error {
	public init() {}
}

// 16 byte key
@RAW_staticbuff(bytes:16)
public struct Key16:Sendable, Equatable {}

// 32 byte key
@RAW_staticbuff(bytes:32)
public struct Key32:Sendable, Equatable {}

public struct Context {
	private var ctx:__crawdog_chachapoly_ctx

	public init?(key:UnsafeRawBufferPointer) {
		var newContext = __crawdog_chachapoly_ctx()
		switch key.count {
			case MemoryLayout<Key16>.size:
				fallthrough
			case MemoryLayout<Key32>.size:
				_ = __crawdog_chachapoly_init(&newContext, key.baseAddress!, Int32(key.count))
			default:
				return nil
		}
		self.ctx = newContext
	}
	
	public init?(key:UnsafeBufferPointer<UInt8>) {
		var newContext = __crawdog_chachapoly_ctx()
		switch key.count {
			case MemoryLayout<Key16>.size:
				fallthrough
			case MemoryLayout<Key32>.size:
				_ = __crawdog_chachapoly_init(&newContext, key.baseAddress!, Int32(key.count))
			default:
				return nil
		}
		self.ctx = newContext
	}

	// pointer to 32 byte key
	public init<K32P>(key:UnsafePointer<K32P>) where K32P:RAW_staticbuff, K32P.RAW_staticbuff_storetype == Key32.RAW_staticbuff_storetype {
		var newContext = __crawdog_chachapoly_ctx()
		_ = __crawdog_chachapoly_init(&newContext, key, Int32(MemoryLayout<K32P>.size))
		self.ctx = newContext
	}

	// pointer to 16 byte key
	public init<K16P>(key:UnsafePointer<K16P>) where K16P:RAW_staticbuff, K16P.RAW_staticbuff_storetype == Key16.RAW_staticbuff_storetype {
		var newContext = __crawdog_chachapoly_ctx()
		_ = __crawdog_chachapoly_init(&newContext, key, Int32(MemoryLayout<K16P>.size))
		self.ctx = newContext
	}
	
	// 16 byte key
	public init<K16>(key:borrowing K16) where K16:RAW_staticbuff, K16.RAW_staticbuff_storetype == Key16.RAW_staticbuff_storetype{
		var newContext = __crawdog_chachapoly_ctx()
		key.RAW_access_staticbuff {
			_ = __crawdog_chachapoly_init(&newContext, $0, Int32(MemoryLayout<K16>.size))
		}
		self.ctx = newContext
	}
	
	// 32 byte key
	public init<K32>(key:borrowing K32) where K32:RAW_staticbuff, K32.RAW_staticbuff_storetype == Key32.RAW_staticbuff_storetype {
		var newContext = __crawdog_chachapoly_ctx()
		key.RAW_access_staticbuff {
			_ = __crawdog_chachapoly_init(&newContext, $0, Int32(MemoryLayout<K32>.size))
		}
		self.ctx = newContext
	}


	/// execute authenticated encryption with associated data.
	/// - parameters:
	///		- nonce: the nonce to use for this encryption
	///		- associatedData: the associated data to use for this encryption. may be zero length.
	///		- inputData: the data to encrypt
	///		- output: the output buffer to write the encrypted data to. must be at least as large as the input data.
	/// - returns: the tag that was generated for this encryption
	public mutating func encrypt(nonce:consuming Nonce, associatedData:UnsafeBufferPointer<UInt8>, inputData:UnsafeBufferPointer<UInt8>, output:UnsafeMutablePointer<UInt8>) throws -> Tag {
		var newTag = Tag()
		switch nonce.RAW_access_staticbuff({ noncePtr in
			return newTag.RAW_access_staticbuff_mutating { tagPtr in
				return __crawdog_chachapoly_crypt(&ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 1)
			}
		}) {
			case 0:
				return newTag
			case __CRAWDOG_CHACHAPOLY_INVALID_MAC:
				throw InvalidMACError()
			default:
				fatalError("unknown error thrown from rawdog chachapoly impl")
		}
	}

	/// execute authenticated decryption with associated data.
	/// - parameters:
	///		- tag: the tag to authenticate the decryption
	///		- nonce: the nonce to use for this decryption
	///		- associatedData: the associated data to use for this decryption. may be zero length.
	public mutating func decrypt(tag:consuming Tag, nonce:consuming Nonce, associatedData:UnsafeBufferPointer<UInt8>, inputData:UnsafeBufferPointer<UInt8>, output:UnsafeMutablePointer<UInt8>) throws {
		switch nonce.RAW_access_staticbuff({ noncePtr in
			tag.RAW_access_staticbuff_mutating { tagPtr in 
				__crawdog_chachapoly_crypt(&ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 0)
			}
		}) {
			case 0:
				return
			case __CRAWDOG_CHACHAPOLY_INVALID_MAC:
				throw InvalidMACError()
			default:
				fatalError("unknown error thrown from rawdog chachapoly impl")
		}
	}
}