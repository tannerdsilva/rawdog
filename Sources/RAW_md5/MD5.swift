import __crawdog_md5
import RAW

/// a static length structure representing a MD5 hash result.
@RAW_staticbuff(bytes:16)
public struct Hash:Sendable{}

/// a MD5 hasher.
public struct Hasher<RAW_hasher_outputtype:RAW_staticbuff>:RAW_hasher where RAW_hasher_outputtype.RAW_fixed_type == Hash.RAW_fixed_type {
	private var context:__crawdog_md5_context
	
	public static var RAW_hasher_blocksize:Int { Int(__CRAWDOG_MD5_BLOCK_SIZE * 4) }

	public typealias RAW_hasher_outputtype = Hash

	public init() {
		context = __crawdog_md5_context()
		__crawdog_md5_init(&context)
	}

	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_md5_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
	
	public mutating func update(_ buffer:UnsafeBufferPointer<UInt8>) {
		__crawdog_md5_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
		
	public mutating func update(_ data:UnsafeRawPointer, count:Int) {
		__crawdog_md5_update(&context, data, UInt32(count))
	}
	
	public mutating func finish(into pointer:UnsafeMutableRawPointer) throws {
		__crawdog_md5_finish(&context, pointer.assumingMemoryBound(to:__crawdog_md5_output.self))
	}

}