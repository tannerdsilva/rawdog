import __crawdog_sha256
import RAW

public struct Hasher:RAW_hasher {
	public static let RAW_hasher_blocksize = size_t(__CRAWDOG_SHA256_BLOCK_SIZE)
	public static let RAW_hasher_outputsize:size_t = size_t(__CRAWDOG_SHA256_HASH_SIZE)

	private var context:__crawdog_sha256_context
	public init() {
		context = __crawdog_sha256_context()
		__crawdog_sha256_init(&context)
	}

	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_sha256_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}

	@discardableResult public mutating func finish(into output:UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer {
		__crawdog_sha256_finish(&context, output.assumingMemoryBound(to:SHA256_HASH.self))
		return output + Self.RAW_hasher_outputsize
	}
}