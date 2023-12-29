import RAW
import CRAW
import CRAW_base64

/// error thrown by Base64 encoding/decoding functions
public enum Error:Swift.Error {
	
	/// the provided string could not be decoded.
	case decodingError(String, Int32)

	/// the provided string could not be encoded.
	case encodingError([UInt8], Int32)

	/// thrown when the provided character is not a valid base64 character.
	case invalidCharacter(UInt8)
}

/// a typealias for the base64 value type.
public typealias Base64Value = Value

// value shall be expressible by an integer literal.
extension Value:ExpressibleByIntegerLiteral {
	/// the type of integer that is used for literal expressions.
	public typealias IntegerLiteralType = UInt8

	/// create a new value from an integer literal.
	public init(integerLiteral value: UInt8) {
		self = try! Self(validate:value)
	}
}

// public struct EncodedData:RAW_encodable {
// 	public func RAW_encoded_size() -> RAW.size_t {
// 		return bytes.count + 1
// 	}

// 	public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		var ptr = ptr
// 		for byte in bytes {
// 			ptr = byte.RAW_encode(ptr:&ptr)
// 		}
// 		return ptr
// 	}

// 	public var bytes:[Value]
// 	public var paddingCount:UInt8

// 	public init(bytes:[Value], paddingCount:UInt8) {
// 		self.bytes = bytes
// 		self.paddingCount = paddingCount
// 	}
// }

public typealias DecodedData = [UInt8]

/// represents one of the possible 64 values that are possible in a base64 encoded string.
/// raw values are the ascii values of the characters.
public enum Value:UInt8 {

	// uppercase letters
	case A = 0x41
	case B = 0x42
	case C = 0x43
	case D = 0x44
	case E = 0x45
	case F = 0x46
	case G = 0x47
	case H = 0x48
	case I = 0x49
	case J = 0x4A
	case K = 0x4B
	case L = 0x4C
	case M = 0x4D
	case N = 0x4E
	case O = 0x4F
	case P = 0x50
	case Q = 0x51
	case R = 0x52
	case S = 0x53
	case T = 0x54
	case U = 0x55
	case V = 0x56
	case W = 0x57
	case X = 0x58
	case Y = 0x59
	case Z = 0x5A

	// lowercase letters
	case a = 0x61
	case b = 0x62
	case c = 0x63
	case d = 0x64
	case e = 0x65
	case f = 0x66
	case g = 0x67
	case h = 0x68
	case i = 0x69
	case j = 0x6A
	case k = 0x6B
	case l = 0x6C
	case m = 0x6D
	case n = 0x6E
	case o = 0x6F
	case p = 0x70
	case q = 0x71
	case r = 0x72
	case s = 0x73
	case t = 0x74
	case u = 0x75
	case v = 0x76
	case w = 0x77
	case x = 0x78
	case y = 0x79
	case z = 0x7A

	// numbers
	case zero = 0x30
	case one = 0x31
	case two = 0x32
	case three = 0x33
	case four = 0x34
	case five = 0x35
	case six = 0x36
	case seven = 0x37
	case eight = 0x38
	case nine = 0x39

	// special characters
	case plus = 0x2B
	case slash = 0x2F

}

extension Value {
	/// get the ascii representation of this base64 value.
	public func asciiValue() -> UInt8 {
		switch self {
			// uppercase letters
			case .A: return 0x41
			case .B: return 0x42
			case .C: return 0x43
			case .D: return 0x44
			case .E: return 0x45
			case .F: return 0x46
			case .G: return 0x47
			case .H: return 0x48
			case .I: return 0x49
			case .J: return 0x4A
			case .K: return 0x4B
			case .L: return 0x4C
			case .M: return 0x4D
			case .N: return 0x4E
			case .O: return 0x4F
			case .P: return 0x50
			case .Q: return 0x51
			case .R: return 0x52
			case .S: return 0x53
			case .T: return 0x54
			case .U: return 0x55
			case .V: return 0x56
			case .W: return 0x57
			case .X: return 0x58
			case .Y: return 0x59
			case .Z: return 0x5A

			// lowercase letters
			case .a: return 0x61
			case .b: return 0x62
			case .c: return 0x63
			case .d: return 0x64
			case .e: return 0x65
			case .f: return 0x66
			case .g: return 0x67
			case .h: return 0x68
			case .i: return 0x69
			case .j: return 0x6A
			case .k: return 0x6B
			case .l: return 0x6C
			case .m: return 0x6D
			case .n: return 0x6E
			case .o: return 0x6F
			case .p: return 0x70
			case .q: return 0x71
			case .r: return 0x72
			case .s: return 0x73
			case .t: return 0x74
			case .u: return 0x75
			case .v: return 0x76
			case .w: return 0x77
			case .x: return 0x78
			case .y: return 0x79
			case .z: return 0x7A

			// numbers
			case .zero: return 0x30
			case .one: return 0x31
			case .two: return 0x32
			case .three: return 0x33
			case .four: return 0x34
			case .five: return 0x35
			case .six: return 0x36
			case .seven: return 0x37
			case .eight: return 0x38
			case .nine: return 0x39

			// symbols
			case .plus: return 0x2B
			case .slash: return 0x2F
		}
	}

	/// initialize a base64 value based on a byte value that is already validated to be a valid base64 value.
	/// - NOTE: this function will crash if the provided byte value is not a valid base64 value.
	public init(validated asciiValue:UInt8) {
		switch asciiValue {
			case 0x41:
			self = .A
			case 0x42:
			self = .B
			case 0x43:
			self = .C
			case 0x44:
			self = .D
			case 0x45:
			self = .E
			case 0x46:
			self = .F
			case 0x47:
			self = .G
			case 0x48:
			self = .H
			case 0x49:
			self = .I
			case 0x4A:
			self = .J
			case 0x4B:
			self = .K
			case 0x4C:
			self = .L
			case 0x4D:
			self = .M
			case 0x4E:
			self = .N
			case 0x4F:
			self = .O
			case 0x50:
			self = .P
			case 0x51:
			self = .Q
			case 0x52:
			self = .R
			case 0x53:
			self = .S
			case 0x54:
			self = .T
			case 0x55:
			self = .U
			case 0x56:
			self = .V
			case 0x57:
			self = .W
			case 0x58:
			self = .X
			case 0x59:
			self = .Y
			case 0x5A:
			self = .Z

			// lc:
			case 0x61:
			self = .a
			case 0x62:
			self = .b
			case 0x63:
			self = .c
			case 0x64:
			self = .d
			case 0x65:
			self = .e
			case 0x66:
			self = .f
			case 0x67:
			self = .g
			case 0x68:
			self = .h
			case 0x69:
			self = .i
			case 0x6A:
			self = .j
			case 0x6B:
			self = .k
			case 0x6C:
			self = .l
			case 0x6D:
			self = .m
			case 0x6E:
			self = .n
			case 0x6F:
			self = .o
			case 0x70:
			self = .p
			case 0x71:
			self = .q
			case 0x72:
			self = .r
			case 0x73:
			self = .s
			case 0x74:
			self = .t
			case 0x75:
			self = .u
			case 0x76:
			self = .v
			case 0x77:
			self = .w
			case 0x78:
			self = .x
			case 0x79:
			self = .y
			case 0x7A:
			self = .z

			// number
			case 0x30:
			self = .zero
			case 0x31:
			self = .one
			case 0x32:
			self = .two
			case 0x33:
			self = .three
			case 0x34:
			self = .four
			case 0x35:
			self = .five
			case 0x36:
			self = .six
			case 0x37:
			self = .seven
			case 0x38:
			self = .eight
			case 0x39:
			self = .nine

			// symbols
			case 0x2B:
			self = .plus
			case 0x2F:
			self = .slash

			default:
			fatalError()
		}
	}

	public init(validate asciiValue:UInt8) throws {
		switch asciiValue {
			case 0x41:
			self = .A
			case 0x42:
			self = .B
			case 0x43:
			self = .C
			case 0x44:
			self = .D
			case 0x45:
			self = .E
			case 0x46:
			self = .F
			case 0x47:
			self = .G
			case 0x48:
			self = .H
			case 0x49:
			self = .I
			case 0x4A:
			self = .J
			case 0x4B:
			self = .K
			case 0x4C:
			self = .L
			case 0x4D:
			self = .M
			case 0x4E:
			self = .N
			case 0x4F:
			self = .O
			case 0x50:
			self = .P
			case 0x51:
			self = .Q
			case 0x52:
			self = .R
			case 0x53:
			self = .S
			case 0x54:
			self = .T
			case 0x55:
			self = .U
			case 0x56:
			self = .V
			case 0x57:
			self = .W
			case 0x58:
			self = .X
			case 0x59:
			self = .Y
			case 0x5A:
			self = .Z

			// lc:
			case 0x61:
			self = .a
			case 0x62:
			self = .b
			case 0x63:
			self = .c
			case 0x64:
			self = .d
			case 0x65:
			self = .e
			case 0x66:
			self = .f
			case 0x67:
			self = .g
			case 0x68:
			self = .h
			case 0x69:
			self = .i
			case 0x6A:
			self = .j
			case 0x6B:
			self = .k
			case 0x6C:
			self = .l
			case 0x6D:
			self = .m
			case 0x6E:
			self = .n
			case 0x6F:
			self = .o
			case 0x70:
			self = .p
			case 0x71:
			self = .q
			case 0x72:
			self = .r
			case 0x73:
			self = .s
			case 0x74:
			self = .t
			case 0x75:
			self = .u
			case 0x76:
			self = .v
			case 0x77:
			self = .w
			case 0x78:
			self = .x
			case 0x79:
			self = .y
			case 0x7A:
			self = .z

			// number
			case 0x30:
			self = .zero
			case 0x31:
			self = .one
			case 0x32:
			self = .two
			case 0x33:
			self = .three
			case 0x34:
			self = .four
			case 0x35:
			self = .five
			case 0x36:
			self = .six
			case 0x37:
			self = .seven
			case 0x38:
			self = .eight
			case 0x39:
			self = .nine

			// symbols
			case 0x2B:
			self = .plus
			case 0x2F:
			self = .slash

			default:
			fatalError()
		}
	}
}

extension Value:Equatable, Hashable {
	// conformance to hashable.
	// - pass the ascii representation of the value to the hasher.
	public func hash(into hasher:inout Hasher) {
		hasher.combine(self.asciiValue())
	}

	public static func == (lhs:Value, rhs:Value) -> Bool {
		switch (lhs, rhs) {
			case (.A, .A): return true
			case (.B, .B): return true
			case (.C, .C): return true
			case (.D, .D): return true
			case (.E, .E): return true
			case (.F, .F): return true
			case (.G, .G): return true
			case (.H, .H): return true
			case (.I, .I): return true
			case (.J, .J): return true
			case (.K, .K): return true
			case (.L, .L): return true
			case (.M, .M): return true
			case (.N, .N): return true
			case (.O, .O): return true
			case (.P, .P): return true
			case (.Q, .Q): return true
			case (.R, .R): return true
			case (.S, .S): return true
			case (.T, .T): return true
			case (.U, .U): return true
			case (.V, .V): return true
			case (.W, .W): return true
			case (.X, .X): return true
			case (.Y, .Y): return true
			case (.Z, .Z): return true

			case (.a, .a): return true
			case (.b, .b): return true
			case (.c, .c): return true
			case (.d, .d): return true
			case (.e, .e): return true
			case (.f, .f): return true
			case (.g, .g): return true
			case (.h, .h): return true
			case (.i, .i): return true
			case (.j, .j): return true
			case (.k, .k): return true
			case (.l, .l): return true
			case (.m, .m): return true
			case (.n, .n): return true
			case (.o, .o): return true
			case (.p, .p): return true
			case (.q, .q): return true
			case (.r, .r): return true
			case (.s, .s): return true
			case (.t, .t): return true
			case (.u, .u): return true
			case (.v, .v): return true
			case (.w, .w): return true
			case (.x, .x): return true
			case (.y, .y): return true
			case (.z, .z): return true
			
			case (.one, .one): return true
			case (.two, .two): return true
			case (.three, .three): return true
			case (.four, .four): return true
			case (.five, .five): return true
			case (.six, .six): return true
			case (.seven, .seven): return true
			case (.eight, .eight): return true
			case (.nine, .nine): return true

			case (.plus, .plus): return true
			case (.slash, .slash): return true

			default: return false
		}
	}
	
}

internal struct RFC4648 {

	/// encoding index map
	internal struct EncodeMap {

		/// get the base64 character for the given index.
		public static subscript(_ index:Int) -> Base64Value {
			switch index {

			// uppercase letters
			case 0: return .A
			case 1: return .B
			case 2: return .C
			case 3: return .D
			case 4: return .E
			case 5: return .F
			case 6: return .G
			case 7: return .H
			case 8: return .I
			case 9: return .J
			case 10: return .K
			case 11: return .L
			case 12: return .M
			case 13: return .N
			case 14: return .O
			case 15: return .P
			case 16: return .Q
			case 17: return .R
			case 18: return .S
			case 19: return .T
			case 20: return .U
			case 21: return .V
			case 22: return .W
			case 23: return .X
			case 24: return .Y
			case 25: return .Z

			// lowercase letters
			case 26: return .a
			case 27: return .b
			case 28: return .c
			case 29: return .d
			case 30: return .e
			case 31: return .f
			case 32: return .g
			case 33: return .h
			case 34: return .i
			case 35: return .j
			case 36: return .k
			case 37: return .l
			case 38: return .m
			case 39: return .n
			case 40: return .o
			case 41: return .p
			case 42: return .q
			case 43: return .r
			case 44: return .s
			case 45: return .t
			case 46: return .u
			case 47: return .v
			case 48: return .w
			case 49: return .x
			case 50: return .y
			case 51: return .z

			// digits 0-9
			case 52: return .zero
			case 53: return .one
			case 54: return .two
			case 55: return .three
			case 56: return .four
			case 57: return .five
			case 58: return .six
			case 59: return .seven
			case 60: return .eight
			case 61: return .nine

			// special characters
			case 62: return .plus
			case 63: return .slash

			default: fatalError()
			}
		}
	}
}

extension RFC4648 {
	public static let decodeMap:[UInt8] = [
		0xff, 0xff, 0xff, 0xff, 0xff, /* 0 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 5 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 10 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 15 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 20 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 25 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 30 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 35 */
		0xff, 0xff, 0xff, 0x3e, 0xff, /* 40 */
		0xff, 0xff, 0x3f, 0x34, 0x35, /* 45 */
		0x36, 0x37, 0x38, 0x39, 0x3a, /* 50 */
		0x3b, 0x3c, 0x3d, 0xff, 0xff, /* 55 */
		0xff, 0xff, 0xff, 0xff, 0xff, /* 60 */
		0x00, 0x01, 0x02, 0x03, 0x04, /* 65 A */
		0x05, 0x06, 0x07, 0x08, 0x09, /* 70 */
		0x0a, 0x0b, 0x0c, 0x0d, 0x0e, /* 75 */
		0x0f, 0x10, 0x11, 0x12, 0x13, /* 80 */
		0x14, 0x15, 0x16, 0x17, 0x18, /* 85 */
		0x19, 0xff, 0xff, 0xff, 0xff, /* 90 */
		0xff, 0xff, 0x1a, 0x1b, 0x1c, /* 95 */
		0x1d, 0x1e, 0x1f, 0x20, 0x21, /* 100 */
		0x22, 0x23, 0x24, 0x25, 0x26, /* 105 */
		0x27, 0x28, 0x29, 0x2a, 0x2b, /* 110 */
		0x2c, 0x2d, 0x2e, 0x2f, 0x30, /* 115 */
		0x31, 0x32, 0x33, 0xff, 0xff, /* 120 */
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, /* 125 */
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, /* 155 */
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, /* 185 */
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, /* 215 */
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, /* 245 */
	]
}

internal func base64_encoded_length_with_padding(_ bytes:size_t) -> size_t {
	return ((bytes + 2) / 3) * 4
}

internal func base64_encoded_length_without_padding(_ bytes:size_t) -> size_t {
	let fullBlocks = bytes / 3
	let remainingBytes = bytes % 3

	// each full block of 3 bytes becomes 4 bytes in Base64
	let fullBlockLength = fullBlocks * 4

	// calculate the length contribution of the remaining bytes
	let remainingBlockLength = remainingBytes > 0 ? (remainingBytes + 1) : 0

	return fullBlockLength + remainingBlockLength
}

internal func sixbit_to_b64(_ sixbit:UInt8) -> Value {
	assert(sixbit <= 63)
	let encodedChar = RFC4648.EncodeMap[Int(sixbit)]
	return encodedChar
}

internal func sixbit_from_b64(_ b64letter:UInt8) throws -> UInt8 {
	let ret = RFC4648.decodeMap[Int(b64letter)]
	switch ret {
		case 0xff:
			throw Error.invalidCharacter(b64letter)
		default:
			return ret
	}
}

func base64_encode_triplet_using_maps(_ dest:UnsafeMutableBufferPointer<Value>, _ src:UnsafePointer<(UInt8, UInt8, UInt8)>) {
	dest[0] = sixbit_to_b64((src.pointee.0 & 0xfc) >> 2)
	dest[1] = sixbit_to_b64(((src.pointee.0 & 0x3) << 4) | ((src.pointee.1 & 0xf0) >> 4))
	dest[2] = sixbit_to_b64(((src.pointee.1 & 0xf) << 2) | ((src.pointee.2 & 0xc0) >> 6))
	dest[3] = sixbit_to_b64(src.pointee.2 & 0x3f)
}

func base64_encode_tail_using_maps(_ dest:UnsafeMutableBufferPointer<Value>, _ destPadding:inout UInt8, _ src:UnsafePointer<(UInt8, UInt8, UInt8)>, _ sourceCount:size_t) {
	var longsrc:(UInt8, UInt8, UInt8)
 	switch sourceCount {
		case 1:
			longsrc = (src.pointee.0, 0, 0)
			destPadding = 2
		case 2:
			longsrc = (src.pointee.0, src.pointee.1, 0)
			destPadding = 1
		case 3:
			longsrc = (src.pointee.0, src.pointee.1, src.pointee.2)
			destPadding = 0
		default:
			fatalError("source length exceeds 3 bytes")
	}
	base64_encode_triplet_using_maps(dest, &longsrc)
}

/// - note: this function assumes that the destination buffer is large enough to hold the encoded data. despite taking the destination buffer size as a parameter, this function does not check that the destination buffer is large enough to hold the encoded data.
func base64_encode_using_maps(ptr:UnsafeRawPointer, size:size_t) -> Encoded {
	let srclen = size
	let encodedLengthWithoutPadding = base64_encoded_length_without_padding(srclen)
	var destPadding:UInt8 = 0
	var srcOffset = 0
	var destOffset = 0
	let byteValues = [Value](unsafeUninitializedCapacity:encodedLengthWithoutPadding, initializingWith: { writeBuffer, sizeThign in
		var srcPtr = ptr
		while (srclen - srcOffset) >= 3 {
			let currentDest = UnsafeMutableBufferPointer(rebasing:writeBuffer[destOffset...])
			base64_encode_triplet_using_maps(currentDest, srcPtr.assumingMemoryBound(to:(UInt8, UInt8, UInt8).self))
			srcOffset += 3
			destOffset += 4
			srcPtr += 3
		}
		if srcOffset < srclen {
			let remainingBytes = srclen - srcOffset
			base64_encode_tail_using_maps(UnsafeMutableBufferPointer(rebasing:writeBuffer[destOffset...]), &destPadding, srcPtr.assumingMemoryBound(to:(UInt8, UInt8, UInt8).self), remainingBytes)
			destOffset += 4
		}
		sizeThign = encodedLengthWithoutPadding
	})
	return Encoded(bytes:byteValues, paddingCount:destPadding)
}

public struct Encoded {
	public var bytes:[Value]
	public var paddingCount:UInt8
}

/// encode a bytestream representatin to a base64 string.
/// - parameter bytes: the byte representation to encode.
/// - throws: ``Error.encodingError`` if the byte representation could not be encoded. this should never be thrown under normal operating conditions.
public func encode<RE>(bytes rawBytes:RE) throws -> Encoded where RE:RAW_encodable {
	let getBuff = [UInt8](RAW_encodable:rawBytes)
	let buffSize = getBuff.count
	return base64_encode_using_maps(ptr:getBuff, size:buffSize)
}

// public func base64_decode_using_maps(ptr:UnsafeRaw)

/// decode a base64 string to a byte array.
/// - parameter dataEncoding: the base64 string to decode.
/// - throws: ``Error.decodingError`` if the base64 string could not be decoded. this should never be thrown under normal operating conditions.
public func decode(_ dataEncoding:String) throws -> [UInt8] {
	let newBytes = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:base64_decoded_length(dataEncoding.count))
	defer {
		newBytes.deallocate()
	}
	let decodeResult = base64_decode(newBytes.baseAddress, base64_decoded_length(dataEncoding.count), dataEncoding, dataEncoding.count)
	guard decodeResult >= 0 else {
		throw Error.decodingError(dataEncoding, geterrno())
	}
	return Array(unsafeUninitializedCapacity:decodeResult, initializingWith: { (buffer, count) in
		memcpy(buffer.baseAddress!, newBytes.baseAddress!, decodeResult)
		count = decodeResult
	})
}