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
		@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
		struct V21Word:RAW_encoded_fixedwidthinteger, Equatable, Sendable {
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

		/// a `RAW_fixed`-only type: the deprecated `RAW_staticbuff_storetype` bridge lives on
		/// the base `RAW_fixed` protocol, so it must resolve on types that never went through
		/// `@RAW_staticbuff`.
		struct V21FixedOnly:RAW_fixed {
			public typealias RAW_fixed_type = (UInt8, UInt8, UInt8, UInt8)
		}

		@available(*, deprecated) // the v21 alias under test is deprecated by design
		@Test("RAW_staticbuff_storetype alias resolves on RAW_fixed-only types")
		func testStoretypeAliasOnFixedOnly() {
			#expect(MemoryLayout<V21FixedOnly.RAW_staticbuff_storetype>.size == MemoryLayout<V21FixedOnly.RAW_fixed_type>.size)
			#expect(MemoryLayout<V21FixedOnly.RAW_staticbuff_storetype>.size == 4)
		}

		/// the EXACT v21 usage pattern: the attached native macro injects
	/// `RAW_encoded_fixedwidthinteger` itself, so a v21 struct that declared no
	/// `RAW_native`-family conformance must compile unchanged (no macro-body move, no
	/// conformance add — the two edits the freestanding form forced).
	@RAW_staticbuff(bytes:4)
	@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
	struct V21NativeOnly:RAW_staticbuff, Equatable, Sendable, ExpressibleByIntegerLiteral {}

	@Test("exact v21 native-macro usage compiles unchanged (conformance auto-injected)")
	func testV21NativeOnlyPattern() {
		let word:V21NativeOnly = 0xDEADBEEF
		#expect(word.RAW_native() == 0xDEADBEEF)
		#expect(MemoryLayout<V21NativeOnly.RAW_fixed_type>.size == 4)
	}

	// MARK: v21 hand-written protocol conformances

	/// a v21-style RAW_decodable conformer: hand-written pointer + count initializer
	/// (the v22 buffer form is defaulted via the witness table).
	struct V21Decodable:RAW_decodable, Equatable {
		var storage:UInt32

		init(storage:UInt32) {
			self.storage = storage
		}

		init?(RAW_decode ptr:UnsafeRawPointer, count:Int) {
			guard count == MemoryLayout<UInt32>.size else {
				return nil
			}
			self.storage = ptr.loadUnaligned(as:UInt32.self)
		}
	}

	@Test("v21 hand-written two-arg RAW_decode witness + buffer default round-trip")
	func testV21Decodable() {
		let value = V21Decodable(storage: 0xDEADBEEF)
		// v21 call form (deprecated requirement)
		let v21Decoded = withUnsafePointer(to:value.storage) { (ptr:UnsafePointer<UInt32>) -> V21Decodable? in
			return V21Decodable(RAW_decode: UnsafeRawPointer(ptr), count: MemoryLayout<UInt32>.size)
		}
		#expect(v21Decoded == value)
		// v22 call form (default → v21 witness)
		let v22Decoded = withUnsafeBytes(of:value.storage) { (buf:UnsafeRawBufferPointer) -> V21Decodable? in
			return V21Decodable(RAW_decode: buf)
		}
		#expect(v22Decoded == value)
		// wrong size fails
		let wrong = withUnsafePointer(to:value.storage) { (ptr:UnsafePointer<UInt32>) -> V21Decodable? in
			return V21Decodable(RAW_decode: UnsafeRawPointer(ptr), count: 2)
		}
		#expect(wrong == nil)
	}

	/// a v21-style RAW_accessible conformer: hand-written RAW_access / RAW_access_mutating
	/// bodies (the v22 RAW_access_immutable / RAW_access_mutable / RAW_encode forms are
	/// defaulted via the witness table).
	struct V21Accessible:RAW_accessible, RAW_encodable {
		var bytes:(UInt8, UInt8, UInt8, UInt8)

		@available(*, deprecated)
		public borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
			return try withUnsafePointer(to:bytes) { (ptr:UnsafePointer<(UInt8, UInt8, UInt8, UInt8)>) throws(E) -> R in
				let bytePtr = UnsafeRawPointer(ptr).assumingMemoryBound(to:UInt8.self)
				return try body(UnsafeBufferPointer<UInt8>(start:bytePtr, count:MemoryLayout<UInt8>.size * 4))
			}
		}

		@available(*, deprecated)
		public mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
			return try withUnsafeMutablePointer(to:&bytes) { (ptr:UnsafeMutablePointer<(UInt8, UInt8, UInt8, UInt8)>) throws(E) -> R in
				let bytePtr = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to:UInt8.self)
				return try body(UnsafeMutableBufferPointer<UInt8>(start:bytePtr, count:MemoryLayout<UInt8>.size * 4))
			}
		}
	}

	@available(*, deprecated) // the v21 access members under test are deprecated by design
	@Test("v21 hand-written RAW_access/RAW_access_mutating witness the v22 accessor defaults")
	func testV21Accessible() {
		var value = V21Accessible(bytes: (0xDE, 0xAD, 0xBE, 0xEF))
		// v21 call form
		let first = value.RAW_access { (buf:UnsafeBufferPointer<UInt8>) -> UInt8 in
			return buf[0]
		}
		#expect(first == 0xDE)
		// v22 call form, defaulted through the v21 witness
		let viaRaw = value.RAW_access_immutable(UnsafeRawBufferPointer.self) { (raw:UnsafeRawBufferPointer) -> UInt8 in
			return raw.load(as:UInt8.self)
		}
		#expect(viaRaw == 0xDE)
		// mutable v21 form
		value.RAW_access_mutating { (buf:UnsafeMutableBufferPointer<UInt8>) in
			buf[3] = 0x42
		}
		#expect(value.bytes.3 == 0x42)
		// v22 mutable default
		value.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { (raw:UnsafeMutableRawBufferPointer) in
			raw.storeBytes(of:0x77, toByteOffset:3, as:UInt8.self)
		}
		#expect(value.bytes.3 == 0x77)
		// RAW_encode defaults work through the accessor chain
		var countout:Int = 0
		value.RAW_encode(count:&countout)
		#expect(countout == 4)
	}

	// MARK: v21 concat compatibility mode

	@RAW_staticbuff(bytes:8)
	@RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
	struct PartA:RAW_encoded_fixedwidthinteger, Equatable, Sendable {}

	@RAW_staticbuff(bytes:2)
	@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
	struct PartB:RAW_encoded_fixedwidthinteger, Equatable, Sendable {}

	/// v21-style concat: the user-declared stored properties ARE the payload (no
	/// `_bytes` member is generated); all access/decode/encode/compare machinery
	/// resolves through the protocol defaults.
	@RAW_staticbuff(concat: PartA.self, PartB.self)
	struct V21ConcatCombo:Sendable {
		var first:PartA
		var second:PartB

		init(first:PartA, second:PartB) {
			self.first = first
			self.second = second
		}
	}

	@available(*, deprecated) // v21 concat members under test are deprecated by design
	@Test("v21 concat stored properties are the payload (access/decode/tuple round trip)")
	func testV21ConcatMode() {
		var combo = V21ConcatCombo(first: PartA(RAW_native: 0x1122334455667788), second: PartB(RAW_native: 0xABCD))
		// v21 access witness reads the payload
		var firstByte:UInt8 = 0
		combo.RAW_access { (buf:UnsafeBufferPointer<UInt8>) in
			firstByte = buf[0]
		}
		#expect(firstByte == 0x11)
		// v22 accessor defaulted through the v21 witness
		let viaImmutable:UInt8 = combo.RAW_access_immutable(UnsafeRawBufferPointer.self) { raw in
			raw.load(as:UInt8.self)
		}
		#expect(viaImmutable == 0x11)
		// v22 mutable default through the v21 mutable witness
		combo.RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { raw in
			raw.storeBytes(of:0x99, toByteOffset:0, as:UInt8.self)
		}
		#expect((combo.first.RAW_native() >> 56) == 0x99)
		// encode + decode round trip through the macro machinery
		var countout:Int = 0
		let bytes = [UInt8](RAW_encodable:&combo, byte_count_out:&countout)
		#expect(countout == 10)
		let decoded = bytes.withUnsafeBytes { V21ConcatCombo(RAW_decode:$0)! }
		#expect((decoded.first.RAW_native() >> 56) == 0x99)
		#expect(decoded.second.RAW_native() == 0xABCD)
		// v21 storetype tuple getter + init round trip
		var combo2 = decoded
		let tuple = combo2.RAW_staticbuff()
		let rebuilt = V21ConcatCombo(RAW_staticbuff: tuple)
		#expect(rebuilt.first.RAW_native() == decoded.first.RAW_native())
		#expect(rebuilt.second.RAW_native() == decoded.second.RAW_native())
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
