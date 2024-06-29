import __crawdog_sha1
import RAW

/// a static length structure representing a SHA1 hash result.
@RAW_staticbuff(bytes:20)
public struct Hash:Sendable{}

/// a SHA1 hasher.
public struct Hasher<RAW_hasher_outputtype:RAW_staticbuff>:RAW_hasher where RAW_hasher_outputtype.RAW_staticbuff_storetype == (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
	public static var RAW_hasher_blocksize:size_t { size_t(__CRAWDOG_SHA1_BLOCK_SIZE) }
	
	public typealias RAW_hasher_outputtype = Hash

	private var context:__crawdog_sha1_context
	public init() {
		context = __crawdog_sha1_context()
		__crawdog_sha1_init(&context)
	}

	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_sha1_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}

	public mutating func finish<S>(into output:inout Optional<S>) throws where S:RAW_staticbuff, S.RAW_staticbuff_storetype == RAW_hasher_outputtype.RAW_staticbuff_storetype {
		output = S(RAW_staticbuff:S.RAW_staticbuff_zeroed())
		output!.RAW_access_staticbuff_mutating {
			__crawdog_sha1_finish(&context, $0.assumingMemoryBound(to:SHA1_HASH.self))
		}
	}
}