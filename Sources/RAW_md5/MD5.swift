import __crawdog_md5
import RAW

public struct Hasher:RAW_hasher {
	public static let RAW_hasher_blocksize = size_t(__CRAWDOG_MD5_BLOCK_SIZE)
	public static let RAW_hasher_outputsize:size_t = size_t(__CRAWDOG_MD5_HASH_SIZE)

	private var context:__crawdog_md5_context
	public init() {
		context = __crawdog_md5_context()
		__crawdog_md5_init(&context)
	}

	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_md5_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}

	@discardableResult public mutating func finish(into output:UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer {
		__crawdog_md5_finish(&context, output.assumingMemoryBound(to:MD5_HASH.self))
		return output + Self.RAW_hasher_outputsize
	}
}