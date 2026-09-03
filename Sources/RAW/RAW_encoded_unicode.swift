// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Darwin

/// this protocol exists to create a slightly cleaner relationship between the two string based RAW_convertible macros.
public protocol RAW_encoded_unicode:RAW_decodable, RAW_encodable, RAW_accessible, RAW_comparable, Sequence<Character> {
	/// the unicode encoding used by this type.
	associatedtype RAW_convertible_unicode_encoding:UnicodeCodec where RAW_convertible_unicode_encoding.CodeUnit:FixedWidthInteger

	/// the integer encoding implementation that backs the unicode encoding.
	associatedtype RAW_integer_encoding_impl:RAW_encoded_fixedwidthinteger where RAW_integer_encoding_impl.RAW_native_type == RAW_convertible_unicode_encoding.CodeUnit
		
	/// initialize from a string's unicode scalar view.
	init(_ string:consuming String.UnicodeScalarView)

	/// create an iterator over the characters of this string.
	consuming func makeIterator() -> RAW_encoded_unicode_iterator<Self>
}

/// internal iterator that translates raw bytes to native code units for comparison.
fileprivate struct RAW_native_translation_iterator<T:RAW_encoded_fixedwidthinteger>:IteratorProtocol {
	internal var count_up:Int
	internal let count:Int
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
		let result = head.loadUnaligned(as: T.RAW_native_type.self)
		head = head.advanced(by: MemoryLayout<T.RAW_native_type>.size)
		count_up += MemoryLayout<T.RAW_native_type>.size
		return result
	}
}

extension RAW_encoded_unicode {
	/// initialize from a `String` value.
	public init(_ str:consuming String) {
		self.init(str.unicodeScalars)
	}

	/// compare two encoded unicode values by decoding and comparing scalar-by-scalar.
	public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:Int, rhs_data:UnsafeRawPointer, rhs_count:Int) -> Int32 {
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
					return -1
				}
			default:
				switch rhsResult {
				case (.scalarValue(_)):
					return 1
				default:
					return 0
				}
			}
		}
	}
}

extension RAW_encoded_unicode where Self:ExpressibleByStringLiteral {
	/// initialize from a string literal.
	public init(stringLiteral value: String) {
		self.init(value)
	}
}

/// internal iterator that reads code units from stored bytes.
fileprivate struct RAW_string_bytes_to_codeunit_unicode<I:RAW_encoded_unicode>:IteratorProtocol {
	private let storedBytes:[UInt8]
	private var byte_seeker:Int = 0
	fileprivate init(storedBytes:consuming [UInt8]) {
		self.storedBytes = storedBytes
	}
	fileprivate mutating func next() -> I.RAW_convertible_unicode_encoding.CodeUnit? {
		guard byte_seeker < storedBytes.count && (storedBytes.count - byte_seeker) >= MemoryLayout<I.RAW_convertible_unicode_encoding.CodeUnit>.size else {
			return nil
		}
		return storedBytes.withUnsafeBytes { bytes in
			let start = bytes.baseAddress!.advanced(by:byte_seeker)
			let nextItem = start.loadUnaligned(as: I.RAW_convertible_unicode_encoding.CodeUnit.self)
			byte_seeker += MemoryLayout<I.RAW_convertible_unicode_encoding.CodeUnit>.size
			return nextItem
		}
	}
}

/// public iterator that produces `Character` values from an encoded unicode type.
public struct RAW_encoded_unicode_iterator<T:RAW_encoded_unicode>:IteratorProtocol {
	private var codeUnitTranslator:RAW_string_bytes_to_codeunit_unicode<T>
	private var decoder:T.RAW_convertible_unicode_encoding
	/// create an iterator over the raw bytes of an encoded unicode type.
	public init(_ encodedType:consuming [UInt8], encoding:T.Type) {
		codeUnitTranslator = RAW_string_bytes_to_codeunit_unicode<T>(storedBytes:encodedType)
		decoder = T.RAW_convertible_unicode_encoding()
	}
	/// advance to the next decoded `Character`, or nil at the end of the data.
	public mutating func next() -> Character? {
		switch decoder.decode(&codeUnitTranslator) {
		case .scalarValue(let scalar):
			return Character(scalar)
		default:
			return nil
		}
	}
}
