import __crawdog_md5
import RAW

/// a static length structure representing a MD5 hash result.
@RAW_staticbuff(bytes:16)
public struct Hash:Sendable{}

/// a MD5 hasher.
public struct Hasher:RAW_hasher {
	/// the output type of this hasher.
	public typealias RAW_hasher_outputtype = Hash
	/// the block size of this hasher, in bytes.
	public static var RAW_hasher_blocksize:Int { Int(__CRAWDOG_MD5_BLOCK_SIZE * 4) }

	private var context:__crawdog_md5_context
	/// create a new hasher context.
	public init() {
		context = __crawdog_md5_context()
		__crawdog_md5_init(&context)
	}
	/// update the hasher with a raw byte buffer.
	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_md5_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
	/// finish the hasher, writing the digest to the given pointer.
	public mutating func finish(into pointer:UnsafeMutableRawPointer) throws {
		__crawdog_md5_finish(&context, pointer.assumingMemoryBound(to:__crawdog_md5_output.self))
	}
}
