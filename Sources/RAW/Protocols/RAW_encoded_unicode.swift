/// this protocol exists to create a slightly cleaner relationship between the two string based RAW_convertible macros (``RAW_convertible_string_type_macro`` and ``RAW_convertible_string_init_macro``).
public protocol RAW_encoded_unicode:RAW_convertible, RAW_accessible, Sequence<Character>, RAW_comparable, Comparable, Equatable {
	associatedtype RAW_convertible_unicode_encoding:UnicodeCodec where RAW_convertible_unicode_encoding.CodeUnit:FixedWidthInteger

	associatedtype RAW_integer_encoding_impl:RAW_encoded_fixedwidthinteger where RAW_integer_encoding_impl.RAW_native_type == RAW_convertible_unicode_encoding.CodeUnit
		
	init(_ string:consuming String.UnicodeScalarView)

	consuming func makeIterator() -> RAW_encoded_unicode_iterator<Self>
}

fileprivate struct RAW_native_translation_iterator<T:RAW_encoded_fixedwidthinteger>:IteratorProtocol {
	internal var count_up:size_t
	internal let count:size_t
	private var head:UnsafeRawPointer
	fileprivate init(buffer:UnsafeBufferPointer<UInt8>) {
		count = buffer.count
		count_up = 0
		head = UnsafeRawPointer(buffer.baseAddress!)
	}
	fileprivate mutating func next() -> T.RAW_native_type? {
		guard count_up < count else {
			return nil
		}
		let startPtr = head
		let native = T.init(RAW_staticbuff_seeking: &head)
		count_up += startPtr.distance(to:head)
		return native.RAW_native()
	}
}

extension RAW_encoded_unicode {
	public init(_ str:consuming String) {
		self.init(str.unicodeScalars)
	}

	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
		var lhsBuffer = RAW_native_translation_iterator<RAW_integer_encoding_impl>(buffer:UnsafeBufferPointer<UInt8>(start:lhs_data.assumingMemoryBound(to:UInt8.self), count:lhs_count))
		var lhsDecoder = RAW_convertible_unicode_encoding()
		var rhsBuffer = RAW_native_translation_iterator<RAW_integer_encoding_impl>(buffer:UnsafeBufferPointer<UInt8>(start:rhs_data.assumingMemoryBound(to:UInt8.self), count:rhs_count))
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
					return 0
				}
			}
		}
	}
}

extension RAW_encoded_unicode where Self:ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(value)
	}
}

fileprivate struct RAW_string_bytes_to_codeunit_unicode<I:RAW_encoded_unicode>:IteratorProtocol {
	private let storedBytes:[UInt8]
	private var byte_seeker:size_t = 0
	fileprivate init(storedBytes:consuming [UInt8]) {
		self.storedBytes = storedBytes
	}
	fileprivate mutating func next() -> I.RAW_convertible_unicode_encoding.CodeUnit? {
		return storedBytes.RAW_access({ bytes in
			guard byte_seeker < bytes.count && (bytes.count - byte_seeker) >= MemoryLayout<I.RAW_convertible_unicode_encoding.CodeUnit>.size else {
				return nil
			}
			let start = bytes.baseAddress!.advanced(by:byte_seeker)
			let nextItem = I.RAW_integer_encoding_impl(RAW_staticbuff:start).RAW_native()
			byte_seeker += MemoryLayout<I.RAW_convertible_unicode_encoding.CodeUnit>.size
			return nextItem
		})
	}
}

public struct RAW_encoded_unicode_iterator<T:RAW_encoded_unicode>:IteratorProtocol {
	private var codeUnitTranslator:RAW_string_bytes_to_codeunit_unicode<T>
	private var decoder:T.RAW_convertible_unicode_encoding
	public init(_ encodedType:consuming [UInt8], encoding:T.Type) {
		codeUnitTranslator = RAW_string_bytes_to_codeunit_unicode<T>(storedBytes:encodedType)
		decoder = T.RAW_convertible_unicode_encoding()
	}
	public mutating func next() -> Character? {
		switch decoder.decode(&codeUnitTranslator) {
		case .scalarValue(let scalar):
			return Character(scalar)
		default:
			return nil
		}
	}
}