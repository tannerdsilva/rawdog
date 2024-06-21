// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_xchachapoly
import RAW
import RAW_chachapoly
import __crawdog_chachapoly

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
	///		- nonce: the nonce to use for this encryption
	///		- associatedData: the associated data to use for this encryption. may be zero length.
	///		- inputData: the data to encrypt
	///		- output: the output buffer to write the encrypted data to. must be at least as large as the input data.
	/// - returns: the tag that was generated for this encryption
	public mutating func encrypt(nonce:consuming Nonce, associatedData:UnsafeRawBufferPointer, inputData:UnsafeMutableRawBufferPointer, output:UnsafeMutableRawPointer) throws -> Tag {
		var newTag = Tag()
		let result = nonce.RAW_access_staticbuff { noncePtr in
			return newTag.RAW_access_staticbuff_mutating { tagPtr in
					return __crawdog_xchachapoly_crypt(&self.ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 1)
				}
			}
		switch result {
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
	public mutating func decrypt(tag:consuming Tag, nonce:consuming Nonce, associatedData:UnsafeRawBufferPointer, inputData:UnsafeMutableRawBufferPointer, output:UnsafeMutableRawPointer) throws {
		let result = nonce.RAW_access_staticbuff { noncePtr in
			tag.RAW_access_staticbuff_mutating { tagPtr in 
				return __crawdog_xchachapoly_crypt(&self.ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 0)
			}
		}
		switch result {
			case 0:
				return
			case __CRAWDOG_XCHACHAPOLY_INVALID_MAC:
				throw InvalidMACError()
			default:
				fatalError("unknown error thrown from rawdog chachapoly impl")
		}
	}
}