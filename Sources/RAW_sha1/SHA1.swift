import __crawdog_sha1
import RAW

/// a static length structure representing a SHA1 hash result.
@RAW_staticbuff(bytes:20)
public struct Hash:Sendable{}

/// a SHA1 hasher.
public struct Hasher:RAW_hasher {
	/// the output type of this hasher.
	public typealias RAW_hasher_outputtype = Hash
	/// the block size of this hasher, in bytes.
	public static var RAW_hasher_blocksize:Int { Int(__CRAWDOG_SHA1_BLOCK_SIZE) }

	private var context:__crawdog_sha1_context
	/// create a new hasher context.
	public init() {
		context = __crawdog_sha1_context()
		__crawdog_sha1_init(&context)
	}
	/// update the hasher with a raw byte buffer.
	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_sha1_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
	/// finish the hasher, writing the digest to the given pointer.
	public mutating func finish(into pointer:UnsafeMutableRawPointer) throws {
		__crawdog_sha1_finish(&context, pointer.assumingMemoryBound(to:__crawdog_sha1_output.self))
	}
}
