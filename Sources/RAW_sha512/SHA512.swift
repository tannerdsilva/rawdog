import __crawdog_sha512
import RAW

public struct Hasher:RAW_hasher {
	public static let RAW_hasher_blocksize = size_t(__CRAWDOG_SHA512_BLOCK_SIZE)
	public static let RAW_hasher_outputsize:size_t = size_t(__CRAWDOG_SHA512_HASH_SIZE)

	private var context:__crawdog_sha512_context
	public init() {
		context = __crawdog_sha512_context()
		__crawdog_sha512_init(&context)
	}

	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_sha512_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}

	@discardableResult public mutating func finish(into output:UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer {
		__crawdog_sha512_finish(&context, output.assumingMemoryBound(to:SHA512_HASH.self))
		return output + Self.RAW_hasher_outputsize
	}
}