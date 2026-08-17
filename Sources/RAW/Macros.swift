import Darwin

public func RAW_memcpy(_ dest:UnsafeMutableRawPointer, _ src:UnsafeRawPointer?, _ count:Int) -> UnsafeMutableRawPointer {
	return memcpy(dest, src, count)
}

@RAW_staticbuff(bytes:5)
internal struct Example1:RAW_staticbuff, RAW_decodable { }

@RAW_staticbuff(bytes:8)
internal struct Example2:RAW_staticbuff, RAW_decodable { }

@RAW_staticbuff(bytes:9)
internal struct Example3:RAW_staticbuff, RAW_decodable { }

@RAW_staticbuff(concat: Example1.self, Example2.self, Example3.self)
struct StaticBuffConcatMacro:RAW_staticbuff, RAW_decodable { }


// @RAW_fixed(bytes:8)
// struct Example2:RAW_fixed {
// 	#RAW_fixed_type(bytes:8)
// }

// @RAW_fixed(concat:Example.self, Example2.self)
// struct ExampleConcat {}

// struct ExampleDecode:RAW_decodable {
// 	#RAW_fixed_type(bytes:5)
// 	var _bytes:RAW_fixed_type
	
// 	@RAW_decode_impl(RAW_staticbuff: Example.self, storage: \._bytes)
// 	init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
// 		#RAW_staticbuff_init()
// 	}
// }
