import __crawdog_chachapoly
import RAW

@RAW_staticbuff(bytes:12)
public struct Nonce:Sendable {}

// poly1305 tag is 16 bytes
@RAW_staticbuff(bytes:16)
public struct Tag:Sendable {
	public init() {
		self = Self(RAW_staticbuff:(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
	}
}

public struct InvalidMACError:Swift.Error {}


// 16 byte key
@RAW_staticbuff(bytes:16)
public struct Key16:Sendable {}

// 32 byte key
@RAW_staticbuff(bytes:32)
public struct Key32:Sendable {}


public struct Context {
	private var ctx:__crawdog_chachapoly_ctx

	public init?(key:UnsafeRawBufferPointer) {
		guard key.count == 16 || key.count == 32 else {
			return nil
		}
		var newContext = __crawdog_chachapoly_ctx()
		__crawdog_chachapoly_init(&newContext, key.baseAddress, Int32(key.count))
		self.ctx = newContext
	}
	
	public init(key:borrowing Key32) {
		var newContext = __crawdog_chachapoly_ctx()
		key.RAW_access_staticbuff {
			_ = __crawdog_chachapoly_init(&newContext, $0, Int32(MemoryLayout<Key32>.size))
		}
		self.ctx = newContext
	}
	
	public init(key:borrowing Key16) {
		var newContext = __crawdog_chachapoly_ctx()
		key.RAW_access_staticbuff {
			_ = __crawdog_chachapoly_init(&newContext, $0, Int32(MemoryLayout<Key16>.size))
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
					return __crawdog_chachapoly_crypt(&self.ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 1)
				}
			}
		switch result {
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
	public mutating func decrypt(tag:consuming Tag, nonce:consuming Nonce, associatedData:UnsafeRawBufferPointer, inputData:UnsafeMutableRawBufferPointer, output:UnsafeMutableRawPointer) throws {
			let result = nonce.RAW_access_staticbuff { noncePtr in
				tag.RAW_access_staticbuff_mutating { tagPtr in 
					return __crawdog_chachapoly_crypt(&self.ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), 0)
				}
			}
			switch result {
				case 0:
					return
				case __CRAWDOG_CHACHAPOLY_INVALID_MAC:
					throw InvalidMACError()
				default:
					fatalError("unknown error thrown from rawdog chachapoly impl")
			}
	}
}