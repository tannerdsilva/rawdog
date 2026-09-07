import __crawdog_sha256
import RAW

/// a static length structure representing a SHA256 hash result.
@RAW_staticbuff(bytes:32)
public struct Hash:Sendable {}

/// a SHA256 hasher.
public struct Hasher:RAW_hasher {
	/// the output type of this hasher.
	public typealias RAW_hasher_outputtype = Hash
	/// the block size of this hasher, in bytes.
	public static var RAW_hasher_blocksize:Int { Int(__CRAWDOG_SHA256_BLOCK_SIZE) }

	private var context:__crawdog_sha256_context
	/// create a new hasher context.
	public init() {
		context = __crawdog_sha256_context()
		__crawdog_sha256_init(&context)
	}
	/// update the hasher with a raw byte buffer.
	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_sha256_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
	/// finish the hasher, writing the digest to the given pointer.
	public mutating func finish(into pointer:UnsafeMutableRawPointer) throws {
		__crawdog_sha256_finish(&context, pointer.assumingMemoryBound(to:__crawdog_sha256_output.self))
	}
}
