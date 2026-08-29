// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import Testing
import RAW

extension rawdog_tests {
	/// exercises the v21 compatibility shims: the deprecated forwards (RAW_access,
	/// RAW_access_mutating, RAW_access_staticbuff, RAW_access_staticbuff_mutating),
	/// the RAW_staticbuff_storetype alias, and the single-label storetype
	/// construction path must all compile and behave like their v21 counterparts.
	@Suite("RAW v21 compatibility shims")
	struct RawV21CompatTests {

		@RAW_staticbuff(bytes:4)
		struct V21Word:RAW_encoded_fixedwidthinteger, Equatable, Sendable {
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
		}

		@available(*, deprecated) // the v21 shims under test are deprecated by design
		@Test("RAW_access / RAW_access_staticbuff / RAW_access_mutating forwarders")
		func testAccessForwarders() throws {
			var word = V21Word(RAW_native:0xDEADBEEF)
			// v21 immutable access
			let firstByte = word.RAW_access { (bytes:UnsafeBufferPointer<UInt8>) -> UInt8 in
				return bytes[0]
			}
			#expect(firstByte == 0xDE)
			// v21 raw-pointer access
			let firstRaw = word.RAW_access_staticbuff { ptr -> UInt8 in
				return ptr.assumingMemoryBound(to:UInt8.self).pointee
			}
			#expect(firstRaw == 0xDE)
			// v21 mutable access
			word.RAW_access_mutating { (bytes:UnsafeMutableBufferPointer<UInt8>) in
				bytes[3] = 0x42
			}
			#expect(word.RAW_native() == 0xDEADBE42)
		}

		@available(*, deprecated) // the v21 shims under test are deprecated by design
		@Test("RAW_access_staticbuff_mutating forwarder")
		func testStaticbuffMutatingForwarder() throws {
			var word = V21Word(RAW_native:0x00000000)
			word.RAW_access_staticbuff_mutating { ptr in
				ptr.assumingMemoryBound(to:UInt8.self).pointee = 0xFF
			}
			#expect(word.RAW_native() == 0xFF000000)
		}

		@available(*, deprecated) // the v21 alias under test is deprecated by design
		@Test("RAW_staticbuff_storetype alias matches RAW_fixed_type")
		func testStoretypeAlias() {
			#expect(MemoryLayout<V21Word.RAW_staticbuff_storetype>.size == MemoryLayout<V21Word.RAW_fixed_type>.size)
			#expect(MemoryLayout<V21Word.RAW_staticbuff_storetype>.size == 4)
		}

		@available(*, deprecated) // constructs through RAW_staticbuff storetype
		@Test("single-label storetype construction round-trips")
		func testSingleLabelConstruction() throws {
			let a = V21Word(RAW_native:0x01020304)
			let storage = a.RAW_access_immutable(UnsafeRawBufferPointer.self) { raw in
				return raw.loadUnaligned(as:V21Word.RAW_fixed_type.self)
			}
			let b = V21Word(RAW_staticbuff:storage)
			#expect(a == b)
		}
	}
}
