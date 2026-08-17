import __crawdog_sha1
import RAW

/// a static length structure representing a SHA1 hash result.
@RAW_staticbuff(bytes:20)
public struct Hash:Sendable{}

/// a SHA1 hasher.
public struct Hasher<RAW_hasher_outputtype:RAW_staticbuff>:RAW_hasher where RAW_hasher_outputtype.RAW_fixed_type == (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
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
	
	public mutating func update(_ buffer:UnsafeBufferPointer<UInt8>) {
		__crawdog_sha1_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
		
	public mutating func update(_ data:UnsafeRawPointer, count:size_t) {
		__crawdog_sha1_update(&context, data, UInt32(count))
	}
	
	public mutating func finish(into pointer:UnsafeMutableRawPointer) throws {
		__crawdog_sha1_finish(&context, pointer.assumingMemoryBound(to:__crawdog_sha1_output.self))
	}

}