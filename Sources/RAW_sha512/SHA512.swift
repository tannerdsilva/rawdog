import __crawdog_sha512
import RAW

/// a static length structure representing a SHA512 hash result.
@RAW_staticbuff(bytes:64)
public struct Hash:Sendable {}

/// a SHA512 hasher.
public struct Hasher:RAW_hasher {
	/// the output type of this hasher.
	public typealias RAW_hasher_outputtype = Hash
	/// the block size of this hasher, in bytes.
	public static var RAW_hasher_blocksize:Int { Int(__CRAWDOG_SHA512_BLOCK_SIZE) }

	private var context:__crawdog_sha512_context
	/// create a new hasher context.
	public init() {
		context = __crawdog_sha512_context()
		__crawdog_sha512_init(&context)
	}
	/// update the hasher with a raw byte buffer.
	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_sha512_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
	/// finish the hasher, writing the digest to the given pointer.
	public mutating func finish(into pointer:UnsafeMutableRawPointer) throws {
		__crawdog_sha512_finish(&context, pointer.assumingMemoryBound(to:__crawdog_sha512_output.self))
	}
}
