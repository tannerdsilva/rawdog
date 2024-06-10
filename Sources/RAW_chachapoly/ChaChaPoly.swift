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

public struct Context {
	private var ctx:__crawdog_chachapoly_ctx

	// 16 bytes initializer
	public init(key:borrowing (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) {
		self.ctx = withUnsafePointer(to:key) { keyPtr in
			var newContext = __crawdog_chachapoly_ctx()
			__crawdog_chachapoly_init(&newContext, keyPtr, Int32(MemoryLayout<(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)>.size))
			return newContext
		}
	}

	// 32 bytes initializer
	public init(key:borrowing (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) {
		self.ctx = withUnsafePointer(to:key) { keyPtr in
			var newContext = __crawdog_chachapoly_ctx()
			__crawdog_chachapoly_init(&newContext, keyPtr, Int32(MemoryLayout<(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)>.size))
			return newContext
		}
	}

	public mutating func crypt(encrypt:Bool, nonce:borrowing Nonce, associatedData:UnsafeRawBufferPointer, inputData:UnsafeMutableRawBufferPointer, output:UnsafeMutableRawPointer) -> Int32 {
		var newTag = Tag()
		return nonce.RAW_access_staticbuff { noncePtr in
			return newTag.RAW_access_staticbuff_mutating { tagPtr in
				return __crawdog_chachapoly_crypt(&self.ctx, noncePtr, associatedData.baseAddress, Int32(associatedData.count), inputData.baseAddress, Int32(inputData.count), output, tagPtr, Int32(MemoryLayout<Tag>.size), encrypt == true ? 1 : 0)
			}
		}
	}
}