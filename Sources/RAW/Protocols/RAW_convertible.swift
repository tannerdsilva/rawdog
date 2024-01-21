public typealias RAW_convertible = RAW_encodable & RAW_decodable;

/// this protocol exists to create a slightly cleaner relationship between the two string based RAW_convertible macros (``RAW_convertible_string_type_macro`` and ``RAW_convertible_string_init_macro``).
public protocol RAW_encoded_unicode:RAW_convertible, RAW_accessible, Sequence<Character>, RAW_comparable {
	associatedtype RAW_convertible_unicode_encoding:Unicode.Encoding where RAW_convertible_unicode_encoding.CodeUnit:FixedWidthInteger

	associatedtype RAW_integer_encoding_impl:RAW_encoded_fixedwidthinteger where RAW_integer_encoding_impl.RAW_native_type == RAW_convertible_unicode_encoding.CodeUnit
		
	init(_ string:String.UnicodeScalarView)
}

extension RAW_encoded_unicode where Self:ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(value.unicodeScalars)
	}
}

/// protocol that represents a type that can initialize from a raw representation in memory.
public protocol RAW_decodable {

	/// initialize from the contents of a raw data buffer.
	/// the byte buffer SHOULD be considered comprehensive and exact, meaning that any failure to stride in full should result in a nil return.
	/// - note: the initializer may returrn nil if the value is considered invalid or malformed.
	init?(RAW_decode:UnsafeRawPointer, count:size_t)
}

extension RAW_decodable {
	/// initialize from the contents of a raw data buffer, as a mutable buffer pointer.
	public init?(RAW_accessed ptr:UnsafeMutableBufferPointer<UInt8>) {
		self.init(RAW_decode:ptr.baseAddress!, count:ptr.count)
	}
}


public protocol RAW_encodable {
	/// encodes the size of the given instance to a size_t inout parameter.
	mutating func RAW_encode(count:inout size_t)

	/// encodes the value to the specified pointer.
	/// - returns: the pointer advanced by the number of bytes written. unexpected behavior may occur if the pointer is not advanced by the number of bytes returned in ``RAW_byte_count``.
	mutating func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>
}