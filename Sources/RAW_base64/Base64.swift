import RAW
import CRAW
import CRAW_base64
import Logging

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
		self = Self(rawValue:value)!
	}
}

/// values are 
extension Value:RAW_encodable, RAW_decodable {
	/// encode the base64 value to its ascii byte representation.
	public func asRAW_val<R>(_ valFunc: (UnsafeRawPointer, UnsafePointer<RAW.size_t>) throws -> R) rethrows -> R {
		try rawValue.asRAW_val({
			try valFunc($0, $1)
		})
	}

	/// decode the base64 value from its ascii byte representation.
	public init?(RAW_data: UnsafeRawPointer, RAW_size: UnsafePointer<RAW.size_t>) {
		self = Self(rawValue:UInt8(RAW_data:RAW_data, RAW_size:RAW_size)!)!
	}
}

/// represents one of the possible 64 values that are possible in a base64 encoded string.
public enum Value:UInt8 {

	// upper case
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

	// lower case
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

	init(_ character:Character) throws {
		switch character {
		case "A": self = .A
		case "B": self = .B
		case "C": self = .C
		case "D": self = .D
		case "E": self = .E
		case "F": self = .F
		case "G": self = .G
		case "H": self = .H
		case "I": self = .I
		case "J": self = .J
		case "K": self = .K
		case "L": self = .L
		case "M": self = .M
		case "N": self = .N
		case "O": self = .O
		case "P": self = .P
		case "Q": self = .Q
		case "R": self = .R
		case "S": self = .S
		case "T": self = .T
		case "U": self = .U
		case "V": self = .V
		case "W": self = .W
		case "X": self = .X
		case "Y": self = .Y
		case "Z": self = .Z
		case "a": self = .a
		case "b": self = .b
		case "c": self = .c
		case "d": self = .d
		case "e": self = .e
		case "f": self = .f
		case "g": self = .g
		case "h": self = .h
		case "i": self = .i
		case "j": self = .j
		case "k": self = .k
		case "l": self = .l
		case "m": self = .m
		case "n": self = .n
		case "o": self = .o
		case "p": self = .p
		case "q": self = .q
		case "r": self = .r
		case "s": self = .s
		case "t": self = .t
		case "u": self = .u
		case "v": self = .v
		case "w": self = .w
		case "x": self = .x
		case "y": self = .y
		case "z": self = .z
		case "0": self = .zero
		case "1": self = .one
		case "2": self = .two
		case "3": self = .three
		case "4": self = .four
		case "5": self = .five
		case "6": self = .six
		case "7": self = .seven
		case "8": self = .eight
		case "9": self = .nine
		case "+": self = .plus
		case "/": self = .slash
		default:
			throw Error.invalidCharacter(character.asciiValue!)
		}
	}

	init(_ cchar:CChar) throws {
		guard let character = String(validatingUTF8: [cchar])?.first else {
			throw Error.invalidCharacter(UInt8(bitPattern: cchar))
		}
		try self.init(character)
	}
}

extension Value {
	public static let allValues: Set<Self> = [
		.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z,
		.a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
		.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine,
		.plus, .slash, .equals
	]
}

internal struct RFC4648 {

	/// encoding index map
	internal struct EncodeMap {

		/// get the base64 character for the given index.
		public static subscript(_ index:Int) -> Base64Value {
			switch index {

			// Uppercase letters
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

			// Lowercase letters
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

			// Digits 0-9
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

			// Special characters
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

internal func base64_encoded_length(_ bytes:size_t) -> size_t {
	return ((bytes + 2) / 3) * 4
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

func base64_encode_triplet_using_maps(_ dest:UnsafeMutableBufferPointer<Value>, _ src: UnsafeRawBufferPointer) {
	dest[0] = sixbit_to_b64((src[0] & 0xfc) >> 2)
	dest[1] = sixbit_to_b64(((src[0] & 0x3) << 4) | ((src[1] & 0xf0) >> 4))
	dest[2] = sixbit_to_b64(((src[1] & 0xf) << 2) | ((src[2] & 0xc0) >> 6))
	dest[3] = sixbit_to_b64(src[2] & 0x3f)
}

func base64_encode_tail_using_maps(_ dest:UnsafeMutableBufferPointer<Value>, _ src:UnsafeRawBufferPointer, _ src_len:size_t) {
	var longsrc:(UInt8, UInt8, UInt8)
	switch (src.count % 3) {
		case 0:
			longsrc = (0, 0, 0)
		case 1:
			longsrc = (src[0], 0, 0)
		case 2:
			longsrc = (src[0], src[1], 0)
		case 3:
			longsrc = (src[0], src[1], src[2])
		default:
			fatalError()
	}
	withUnsafePointer(to:longsrc) { longsrcptr in
		base64_encode_triplet_using_maps(dest, UnsafeRawBufferPointer(start:longsrcptr, count:src_len))
		
		//write the = padding characters
		switch (src.count % 3) {
			case 0:
				break
			case 1:
				dest[2] = .equals
				dest[3] = .equals
			case 2:
				dest[3] = .equals
			case 3:
				break
			default:
				fatalError()
		}
}

/// - note: this function assumes that the destination buffer is large enough to hold the encoded data. despite taking the destination buffer size as a parameter, this function does not check that the destination buffer is large enough to hold the encoded data.
func base64_encode_using_maps(_ dest:UnsafeMutableBufferPointer<Value>, _ destlen:size_t, _ src:UnsafeRawBufferPointer, _ srclen:size_t) {
	var srcOffset = 0
	var destOffset = 0
	while srclen - srcOffset >= 3 {
		base64_encode_triplet_using_maps(UnsafeMutableBufferPointer(rebasing:dest[destOffset...]), UnsafeRawBufferPointer(rebasing:src[srcOffset...]))
		srcOffset += 3
		destOffset += 4
	}
	
	if (srclen % 3) > 0 {
		base64_encode_tail_using_maps(UnsafeMutableBufferPointer(rebasing:dest[destOffset...]), UnsafeRawBufferPointer(rebasing:src[srcOffset...]), (srclen % 3))
		destOffset += 4
	}
	memset(&dest[destOffset], 0, destlen - destOffset)
}

/// encode a bytestream representatin to a base64 string.
/// - parameter bytes: the byte representation to encode.
/// - throws: ``Error.encodingError`` if the byte representation could not be encoded. this should never be thrown under normal operating conditions.
public func encode<RE>(bytes rawBytes:RE) throws -> [Value] where RE:RAW_encodable {
	return rawBytes.asRAW_val { rawDat, rawSiz in
		let enclen = base64_encoded_length(rawSiz.pointee) + 1
		let newBytes = UnsafeMutableBufferPointer<Value>.allocate(capacity:enclen)
		defer {
			newBytes.deallocate()
		}
		base64_encode_using_maps(newBytes, enclen, UnsafeRawBufferPointer(start:rawDat, count:rawSiz.pointee), rawSiz.pointee)
		return [Value](RAW_data:newBytes.baseAddress!, RAW_size:rawSiz)
	}
}

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