// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_xchachapoly
import RAW
import RAW_chachapoly
import __crawdog_chachapoly

/// the key type that is used in xchach20apoly1305 operations
public typealias Key = Key32

/// the tag type that is used on xchacha20poly1305 operations
public typealias Tag = RAW_chachapoly.Tag

@RAW_staticbuff(bytes:24)
public struct Nonce:Sendable {}

public struct Context {
	private var ctx:__crawdog_xchachapoly_ctx

	// 32 byte key initialization
	public init?(key:UnsafeRawBufferPointer) {
		switch key.count {
			case MemoryLayout<Key32>.size:
				self.init(key:key.baseAddress!.load(as: Key32.self))
			default:
				return nil
		}
	}
	
	// 32 byte key initialization
	public init(key:borrowing Key32) {
		var newContext = __crawdog_xchachapoly_ctx()
		key.RAW_access_staticbuff {
			__crawdog_xchachapoly_init(&newContext, $0)
		}
		self.ctx = newContext
	}

	/// execute authenticated encryption with associated data.
	/// - parameters:
	///		- nonce: the nonce to use for this encryption. any RAW_staticbuff that is 24 bytes in size can be used here.
	///		- associatedData: the associated data to use for this encryption. may be zero length.
	///		- inputData: the data to encrypt
	///		- output: the output buffer to write the encrypted data to. must be at least as large as the input data.
	/// - returns: the tag that was generated for this encryption
	public mutating func encrypt<N>(nonce:consuming N, associatedData:UnsafeBufferPointer<UInt8>, inputData:UnsafeBufferPointer<UInt8>, output:UnsafeMutablePointer<UInt8>) throws -> Tag where N:RAW_staticbuff, N.RAW_staticbuff_storetype == Nonce.RAW_staticbuff_storetype {
		var newTag = Tag()
		switch nonce.RAW_access_staticbuff({ noncePtr in
			return newTag.RAW_access_staticbuff_mutating { tagPtr in
				__crawdog_xchachapoly_crypt(&ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 1)
			}
		}) {
			case 0:
				return newTag
			case __CRAWDOG_XCHACHAPOLY_INVALID_MAC:
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
	public mutating func decrypt<N>(tag:consuming Tag, nonce:consuming N, associatedData:UnsafeBufferPointer<UInt8>, inputData:UnsafeBufferPointer<UInt8>, output:UnsafeMutablePointer<UInt8>) throws where N:RAW_staticbuff, N.RAW_staticbuff_storetype == Nonce.RAW_staticbuff_storetype {
		switch nonce.RAW_access_staticbuff({ noncePtr in
			tag.RAW_access_staticbuff_mutating { tagPtr in 
				__crawdog_xchachapoly_crypt(&ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 0)
			}
		}) {
			case 0:
				return
			case __CRAWDOG_XCHACHAPOLY_INVALID_MAC:
				throw InvalidMACError()
			default:
				fatalError("unknown error thrown from rawdog chachapoly impl")
		}
	}
}