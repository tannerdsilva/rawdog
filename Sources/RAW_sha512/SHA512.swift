import __crawdog_sha512
import RAW

/// a static length structure representing a SHA512 hash result.
@RAW_staticbuff(bytes:64)
public struct Hash:Sendable {}

public struct Hasher<RAW_hasher_outputtype:RAW_staticbuff>:RAW_hasher where RAW_hasher_outputtype.RAW_fixed_type == (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
	public static var RAW_hasher_blocksize:Int { Int(__CRAWDOG_SHA512_BLOCK_SIZE) }
	public typealias RAW_hasher_outputtype = Hash

	private var context:__crawdog_sha512_context

	public init() {
		context = __crawdog_sha512_context()
		__crawdog_sha512_init(&context)
	}

	public mutating func update(_ buffer:UnsafeRawBufferPointer) {
		__crawdog_sha512_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
	
	public mutating func update(_ buffer:UnsafeBufferPointer<UInt8>) {
		__crawdog_sha512_update(&context, buffer.baseAddress!, UInt32(buffer.count))
	}
		
	public mutating func update(_ data:UnsafeRawPointer, count:Int) {
		__crawdog_sha512_update(&context, data, UInt32(count))
	}
	
	public mutating func finish(into pointer:UnsafeMutableRawPointer) throws {
		__crawdog_sha512_finish(&context, pointer.assumingMemoryBound(to:__crawdog_sha512_output.self))
	}

}