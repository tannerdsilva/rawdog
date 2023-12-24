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
		self = try! Self(validate:value)
	}
}

/// values are 
extension Value:RAW_encodable, RAW_decodable {
    public func RAW_encoded_size() -> RAW.size_t {
        return 1
    }

    public static func RAW_decode(ptr: UnsafeRawPointer, size: RAW.size_t, stride: inout RAW.size_t) -> Value? {
        
    }

	public func RAW_encode(ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return rawValue.RAW_encode(ptr:ptr)
	}

	public init?(RAW_decode:inout UnsafeRawPointer, i:inout RAW.size_t) {
		let ogValPtr:UnsafeRawPointer = RAW_decode
		let ogI = i
		do {
			self = try Self(validate:UInt8(RAW_decode:&RAW_decode, i:&i)!)
		} catch {
			RAW_decode = ogValPtr
			i = ogI
			return nil
		}
	}
}

public struct EncodedData:RAW_encodable {
    public func RAW_encoded_size() -> RAW.size_t {
        return bytes.count + 1
    }

    public var RAW_encoded_size: RAW.size_t {
		return bytes.count
	}

    public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		var afterBytes = bytes.RAW_encode(ptr:ptr)
		for i in 0..<paddingCount {
			afterBytes.advanced(by:Int(i)).assumingMemoryBound(to:UInt8.self).pointee = 0x3D
			afterBytes = afterBytes.advanced(by:1)
		}
		return afterBytes
    }

	public var bytes:[Value]
	public var paddingCount:UInt8

	public init(bytes:[Value], paddingCount:UInt8) {
		self.bytes = bytes
		self.paddingCount = paddingCount
	}
}

public typealias DecodedData = [UInt8]

/// represents one of the possible 64 values that are possible in a base64 encoded string.
public enum Value {

	// alphas
	case A
	case B
	case C
	case D
	case E
	case F
	case G
	case H
	case I
	case J
	case K
	case L
	case M
	case N
	case O
	case P
	case Q
	case R
	case S
	case T
	case U
	case V
	case W
	case X
	case Y
	case Z

	// numbers
	case zero
	case one
	case two
	case three
	case four
	case five
	case six
	case seven
	case eight
	case nine

	// special characters
	case plus
	case slash

}

extension Value {
	/// get the ascii representation of this base64 value.
	func asciiCharacter(useUppercase:Bool = false) -> UInt8 {
		switch (self, useUppercase) {
			// uppercase letters
			case (.A, true): return 0x41
			case (.B, true): return 0x42
			case (.C, true): return 0x43
			case (.D, true): return 0x44
			case (.E, true): return 0x45
			case (.F, true): return 0x46
			case (.G, true): return 0x47
			case (.H, true): return 0x48
			case (.I, true): return 0x49
			case (.J, true): return 0x4A
			case (.K, true): return 0x4B
			case (.L, true): return 0x4C
			case (.M, true): return 0x4D
			case (.N, true): return 0x4E
			case (.O, true): return 0x4F
			case (.P, true): return 0x50
			case (.Q, true): return 0x51
			case (.R, true): return 0x52
			case (.S, true): return 0x53
			case (.T, true): return 0x54
			case (.U, true): return 0x55
			case (.V, true): return 0x56
			case (.W, true): return 0x57
			case (.X, true): return 0x58
			case (.Y, true): return 0x59
			case (.Z, true): return 0x5A

			// lowercase letters
			case (.A, false): return 0x61
			case (.B, false): return 0x62
			case (.C, false): return 0x63
			case (.D, false): return 0x64
			case (.E, false): return 0x65
			case (.F, false): return 0x66
			case (.G, false): return 0x67
			case (.H, false): return 0x68
			case (.I, false): return 0x69
			case (.J, false): return 0x6A
			case (.K, false): return 0x6B
			case (.L, false): return 0x6C
			case (.M, false): return 0x6D
			case (.N, false): return 0x6E
			case (.O, false): return 0x6F
			case (.P, false): return 0x70
			case (.Q, false): return 0x71
			case (.R, false): return 0x72
			case (.S, false): return 0x73
			case (.T, false): return 0x74
			case (.U, false): return 0x75
			case (.V, false): return 0x76
			case (.W, false): return 0x77
			case (.X, false): return 0x78
			case (.Y, false): return 0x79
			case (.Z, false): return 0x7A

			// numbers
			case (.zero, _): return 0x30
			case (.one, _): return 0x31
			case (.two, _): return 0x32
			case (.three, _): return 0x33
			case (.four, _): return 0x34
			case (.five, _): return 0x35
			case (.six, _): return 0x36
			case (.seven, _): return 0x37
			case (.eight, _): return 0x38
			case (.nine, _): return 0x39

			// symbols
			case (.plus, _): return 0x2B
			case (.slash, _): return 0x2F

			default: fatalError()
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
			self = .A
			case 0x62:
			self = .B
			case 0x63:
			self = .C
			case 0x64:
			self = .D
			case 0x65:
			self = .E
			case 0x66:
			self = .F
			case 0x67:
			self = .G
			case 0x68:
			self = .H
			case 0x69:
			self = .I
			case 0x6A:
			self = .J
			case 0x6B:
			self = .K
			case 0x6C:
			self = .L
			case 0x6D:
			self = .M
			case 0x6E:
			self = .N
			case 0x6F:
			self = .O
			case 0x70:
			self = .P
			case 0x71:
			self = .Q
			case 0x72:
			self = .R
			case 0x73:
			self = .S
			case 0x74:
			self = .T
			case 0x75:
			self = .U
			case 0x76:
			self = .V
			case 0x77:
			self = .W
			case 0x78:
			self = .X
			case 0x79:
			self = .Y
			case 0x7A:
			self = .Z

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
			self = .A
			case 0x62:
			self = .B
			case 0x63:
			self = .C
			case 0x64:
			self = .D
			case 0x65:
			self = .E
			case 0x66:
			self = .F
			case 0x67:
			self = .G
			case 0x68:
			self = .H
			case 0x69:
			self = .I
			case 0x6A:
			self = .J
			case 0x6B:
			self = .K
			case 0x6C:
			self = .L
			case 0x6D:
			self = .M
			case 0x6E:
			self = .N
			case 0x6F:
			self = .O
			case 0x70:
			self = .P
			case 0x71:
			self = .Q
			case 0x72:
			self = .R
			case 0x73:
			self = .S
			case 0x74:
			self = .T
			case 0x75:
			self = .U
			case 0x76:
			self = .V
			case 0x77:
			self = .W
			case 0x78:
			self = .X
			case 0x79:
			self = .Y
			case 0x7A:
			self = .Z

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
			case 26: return .A
			case 27: return .B
			case 28: return .C
			case 29: return .D
			case 30: return .E
			case 31: return .F
			case 32: return .G
			case 33: return .H
			case 34: return .I
			case 35: return .J
			case 36: return .K
			case 37: return .L
			case 38: return .M
			case 39: return .N
			case 40: return .O
			case 41: return .P
			case 42: return .Q
			case 43: return .R
			case 44: return .S
			case 45: return .T
			case 46: return .U
			case 47: return .V
			case 48: return .W
			case 49: return .X
			case 50: return .Y
			case 51: return .Z

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

internal func base64_encoded_length_with_padding(_ bytes:size_t) -> size_t {
	return ((bytes + 2) / 3) * 4
}

internal func base64_encoded_length_without_padding(_ bytes:size_t) -> size_t {
	let fullBlocks = bytes / 3
	let remainingBytes = bytes % 3

	// Each full block of 3 bytes becomes 4 bytes in Base64
	let fullBlockLength = fullBlocks * 4

	// Calculate the length contribution of the remaining bytes
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

func base64_encode_triplet_using_maps(_ dest:UnsafeMutableBufferPointer<Value>, _ src:UnsafeRawBufferPointer) {
	dest[0] = sixbit_to_b64((src[0] & 0xfc) >> 2)
	dest[1] = sixbit_to_b64(((src[0] & 0x3) << 4) | ((src[1] & 0xf0) >> 4))
	dest[2] = sixbit_to_b64(((src[1] & 0xf) << 2) | ((src[2] & 0xc0) >> 6))
	dest[3] = sixbit_to_b64(src[2] & 0x3f)
}

func base64_encode_tail_using_maps(_ dest:UnsafeMutableBufferPointer<Value>, _ destPadding:inout UInt8, _ src:UnsafeRawBufferPointer) {
	let sourceCount = src.count
	var longsrc:(UInt8, UInt8, UInt8)
	destPadding = 0
	// idk if this is right
	switch sourceCount {
		case 1:
			longsrc = (src[0], 0, 0)
			destPadding = 2
		case 2:
			longsrc = (src[0], src[1], 0)
			destPadding = 1
		case 3:
			longsrc = (src[0], src[1], src[2])
			destPadding = 0
		default:
			fatalError("source length exceeds 3 bytes")
	}
	withUnsafePointer(to:longsrc) { longsrcptr in
		base64_encode_triplet_using_maps(dest, UnsafeRawBufferPointer(start:longsrcptr, count:sourceCount))
	}
}

/// - note: this function assumes that the destination buffer is large enough to hold the encoded data. despite taking the destination buffer size as a parameter, this function does not check that the destination buffer is large enough to hold the encoded data.
func base64_encode_using_maps(_ src:UnsafeRawBufferPointer) -> Encoded {
	let srclen = src.count
	let writeBuffer = UnsafeMutableBufferPointer<Value>.allocate(capacity:base64_encoded_length_without_padding(srclen))
	var srcOffset = 0
	var destOffset = 0
	var destPadding:UInt8 = 0
	while srclen - srcOffset >= 3 {
		base64_encode_triplet_using_maps(UnsafeMutableBufferPointer(rebasing:writeBuffer[destOffset...]), UnsafeRawBufferPointer(rebasing:src[srcOffset...]))
		srcOffset += 3
		destOffset += 4
	}
	if srcOffset < srclen {
		base64_encode_tail_using_maps(UnsafeMutableBufferPointer(rebasing:writeBuffer[destOffset...]), &destPadding, UnsafeRawBufferPointer(rebasing:src[srcOffset...]))
		destOffset += 4
	}
	return Encoded(bytes:[Value](writeBuffer), paddingCount:destPadding)
}

/// encode a bytestream representatin to a base64 string.
/// - parameter bytes: the byte representation to encode.
/// - throws: ``Error.encodingError`` if the byte representation could not be encoded. this should never be thrown under normal operating conditions.
public func encode<RE>(bytes rawBytes:RE) throws -> [Value] where RE:RAW_encodable {
	return rawBytes.asRAW_val { rawDat, rawSiz in
		base64_encode_using_maps(UnsafeRawBufferPointer(start:rawDat, count:rawSiz.pointee), rawSiz.pointee)
		return [Value](newBytes)
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