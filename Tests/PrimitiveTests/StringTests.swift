import XCTest
import RAW

@RAW_staticbuff(bytes:2)
@RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
struct _uif16 {}


struct _UTF16_str:RAW_encoded_unicode, ExpressibleByStringLiteral, RAW_comparable {

    init(_ string: String) {
        self.init(string.unicodeScalars)
    }
	typealias Element = Character
	
	struct EncodedUnicodeIterator<T:UnicodeCodec>:IteratorProtocol {
		var encoded_bytes:[T.CodeUnit].Iterator
		var decoder:T
		init(_ bytes:[T.CodeUnit].Iterator, encoding:T.Type) {
			encoded_bytes = bytes
			decoder = T()
		}
		mutating func next() -> Character? {
			switch decoder.decode(&encoded_bytes) {
			case .scalarValue(let scalar):
				return Character(scalar)
			default:
				return nil
			}
		}
	}

	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
		struct NativeIterator:IteratorProtocol {
			private let encodingType:RAW_integer_encoding_impl.Type
			var count_up:size_t
			let count:size_t
			private var head:UnsafeRawPointer
			init(buffer:UnsafeBufferPointer<UInt8>, encoding:RAW_integer_encoding_impl.Type) {
				encodingType = encoding
				count = buffer.count
				count_up = 0
				head = UnsafeRawPointer(buffer.baseAddress!)
			}
			mutating func next() -> RAW_integer_encoding_impl.RAW_native_type? {
				guard count_up < count else {
					return nil
				}
				let startPtr = head
				var native = encodingType.init(RAW_staticbuff_seeking: &head)
				count_up += startPtr.distance(to:head)
				return native.RAW_native()
			}
		}
		var lhsBuffer = NativeIterator(buffer:UnsafeBufferPointer<UInt8>(start:lhs_data.assumingMemoryBound(to:UInt8.self), count:lhs_count), encoding:RAW_integer_encoding_impl.self)
		var lhsDecoder = RAW_convertible_unicode_encoding()
		var rhsBuffer = NativeIterator(buffer:UnsafeBufferPointer<UInt8>(start:rhs_data.assumingMemoryBound(to:UInt8.self), count:rhs_count), encoding:RAW_integer_encoding_impl.self)
		var rhsDecoder = RAW_convertible_unicode_encoding()
		mainLoop: while true {
			let lhsResult:UnicodeDecodingResult = lhsDecoder.decode(&lhsBuffer)
			let rhsResult:UnicodeDecodingResult = rhsDecoder.decode(&rhsBuffer)
			switch (lhsResult) {
			case (.scalarValue(let lhsScalar)):
				switch rhsResult {
				case (.scalarValue(let rhsScalar)):
					if lhsScalar != rhsScalar {
						return lhsScalar.value < rhsScalar.value ? -1 : 1
					} else {
						continue mainLoop
					}
				default:
					return -1 // lhs stronger
				}
			default:
				switch rhsResult {
				case (.scalarValue(_)):
					return 1 // rhs stronger
				default:
					if lhsBuffer.count_up == rhsBuffer.count_up {
						return 0
					} else {
						return lhsBuffer.count_up < rhsBuffer.count_up ? -1 : 1
					}
				}
			}
		}
	}

	func makeIterator() -> EncodedUnicodeIterator<RAW_convertible_unicode_encoding> {
		return encoded_bytes.withUnsafeBufferPointer({ encBytes in
			return EncodedUnicodeIterator([RAW_convertible_unicode_encoding.CodeUnit](unsafeUninitializedCapacity:(byte_count / MemoryLayout<RAW_convertible_unicode_encoding.CodeUnit>.size), initializingWith: { buff, usedCount in
				usedCount = 0
				var bytes_base = UnsafeRawPointer(encBytes.baseAddress!)
				let bytes_end = bytes_base.advanced(by: encBytes.count)
				while bytes_base < bytes_end {
					var asNative = RAW_integer_encoding_impl.init(RAW_staticbuff_seeking:&bytes_base)
					buff[usedCount] = asNative.RAW_native()
					usedCount += 1
				}
			}).makeIterator(), encoding:RAW_convertible_unicode_encoding.self)
		})
	}

    mutating func RAW_access_mutating<R>(_ body: (inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
		return try encoded_bytes.RAW_access_mutating(body)
    }

    typealias RAW_integer_encoding_impl = _uif16
	typealias RAW_convertible_unicode_encoding = UTF16

	var byte_count:size_t
	var encoded_bytes:[UInt8]

	init(_ string:String.UnicodeScalarView) {
		var codeUnitView = string.makeIterator()
		var codeUnit:Unicode.Scalar? = codeUnitView.next()
		
		// a character may produce multiple code units. count the required number of code units first.
		var codeUnits:size_t = 0
		while codeUnit != nil {
			defer {
				codeUnit = codeUnitView.next()
			}
			codeUnits += RAW_convertible_unicode_encoding.width(codeUnit!)
		}

		// reset the iterator
		codeUnitView = string.makeIterator()

		// code units may be larger than one byte
		let encoded_bytes = codeUnits * MemoryLayout<RAW_convertible_unicode_encoding.CodeUnit>.size
		
		self.byte_count = encoded_bytes
		self.encoded_bytes = [UInt8](unsafeUninitializedCapacity:encoded_bytes, initializingWith: { asBuffer, countout in
			var scalar:Unicode.Scalar? = codeUnitView.next()
			var curHead = asBuffer.baseAddress!
			while scalar != nil {
				defer {
					scalar = codeUnitView.next()
				}
				RAW_convertible_unicode_encoding.encode(scalar!) { codeUnit in
					var nativeCU = RAW_integer_encoding_impl(RAW_native:codeUnit)
					curHead = nativeCU.RAW_encode(dest:curHead)
				}
			}
			countout = asBuffer.baseAddress!.distance(to: curHead)
			#if DEBUG
			assert(countout == encoded_bytes, "countout is not equal to encoded_bytes")
			#endif
		})
	}

	init?(RAW_decode:UnsafeRawPointer, count:RAW.size_t) {
		guard count % MemoryLayout<RAW_convertible_unicode_encoding.CodeUnit>.size == 0 else {
			return nil
		}

		self.byte_count = count
		self.encoded_bytes = [UInt8](unsafeUninitializedCapacity:count, initializingWith: { asBuffer, countout in
			_ = RAW_memcpy(asBuffer.baseAddress!, RAW_decode, count)
			countout = count
		})
	}

	mutating func RAW_encode(count:inout RAW.size_t) {
		count += byte_count
	}

	mutating func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		encoded_bytes.withUnsafeMutableBufferPointer { buffer in
			_ = RAW_memcpy(dest, buffer.baseAddress!, buffer.count)
		}
		return dest.advanced(by: self.byte_count)
	}
}

class StringTests: XCTestCase {
	// Add your test methods here
	func testRAWEncodeAndDecodeUTF8() {
		var myStarterString:_UTF16_str = "Hello, world!"
		var bcount = 0
		let bytes = [UInt8](RAW_encodable:&myStarterString, byte_count_out:&bcount)
		XCTAssertEqual(bcount, 26)
		XCTAssertEqual(String(myStarterString), "Hello, world!")
	}
}
