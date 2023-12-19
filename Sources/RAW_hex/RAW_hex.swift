import CRAW_hex
import RAW

public enum Error: Swift.Error {
	/// general error that is thrown when a function returns false
	case hexDecodeFailed
	/// general error that is thrown when a function returns false
	case hexEncodeFailed
	/// thrown when the hex string is not a valid hex string.
	case invalidHexCharacter(UInt8)
}

public typealias HexValue = Value

public enum Value:UInt8 {

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
	case a = 0x61
	case b = 0x62
	case c = 0x63
	case d = 0x64
	case e = 0x65
	case f = 0x66

	/// initialize a hex value from a character value.
	/// - throws: `Error.invalidHexCharacter` if the character is not a valid hex character.
	init(_ char:Character) throws {
		switch char {
		case "0":
			self = .zero
		case "1":
			self = .one
		case "2":
			self = .two
		case "3":
			self = .three
		case "4":
			self = .four
		case "5":
			self = .five
		case "6":
			self = .six
		case "7":
			self = .seven
		case "8":
			self = .eight
		case "9":
			self = .nine
		case "a", "A":
			self = .a
		case "b", "B":
			self = .b
		case "c", "C":
			self = .c
		case "d", "D":
			self = .d
		case "e", "E":
			self = .e
		case "f", "F":
			self = .f
		default:
			throw Error.invalidHexCharacter(char.asciiValue!)
		}
	}

	/// initialize a hex value from a c character byte
	/// - throws: `Error.invalidHexCharacter` if the character is not a valid hex character.
	init(_ char:CChar) throws {
		switch char {
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
		case 0x61, 0x41:
			self = .a
		case 0x62, 0x42:
			self = .b
		case 0x63, 0x43:
			self = .c
		case 0x64, 0x44:
			self = .d
		case 0x65, 0x45:
			self = .e
		case 0x66, 0x46:
			self = .f
		default:
			throw Error.invalidHexCharacter(UInt8(bitPattern:char))
		}
	}
}

public typealias HexEncoding = [HexValue]

/// decode a hex string into a buffer of bytes.
/// - parameter hex: the hex string to decode.
public func hex_decode(_ hex:[HexValue]) throws -> [UInt8] {
	let hexDataSize = hex_data_size(hex.count)
	let decodedData = try [UInt8](unsafeUninitializedCapacity:hexDataSize, initializingWith: { (buffer, count) in
		count = hexDataSize
		guard hex_decode(hex, hex.count, buffer.baseAddress!, buffer.count) == true else {
			throw Error.hexDecodeFailed
		}
	})
	return decodedData
}

public func hex_decode<O>(_ hex:String, to:O) throws -> O? where O:RAW_decodable {
	let hexDataSize = hex_data_size(hex.count)
	let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:hexDataSize)
	defer {
		buffer.deallocate()
	}
	guard hex_decode(hex, hex.count, buffer.baseAddress, hexDataSize) == true else {
		throw Error.hexDecodeFailed
	}
	return withUnsafePointer(to:hexDataSize) { (sizePtr) -> O? in
		return O(RAW_data:buffer.baseAddress!, RAW_size:sizePtr)
	}
}

public func hex_encode<I>(_ encodable_input:I) throws -> String where I:RAW_encodable {
	return try encodable_input.asRAW_val { (dataPtr, dataPtrSize) in
		let hexStrSize = hex_str_size(dataPtrSize.pointee)
		let buffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity:hexStrSize)
		defer {
			buffer.deallocate()
		}
		guard hex_encode(dataPtr, dataPtrSize.pointee, buffer.baseAddress, hexStrSize) == true else {
			throw Error.hexEncodeFailed
		}
		return String(cString:buffer.baseAddress!)
	}
}

public func hex_encode<O>(_ data:O) throws -> String where O:RAW_val {
	let hexStrSize = hex_str_size(data.RAW_size)
	let buffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity:hexStrSize)
	defer {
		buffer.deallocate()
	}
	try data.asRAW_val { (dataPtr, dataPtrSize) in
		guard hex_encode(dataPtr, dataPtrSize.pointee, buffer.baseAddress, hexStrSize) == true else {
			throw Error.hexEncodeFailed
		}
	}
	return String(cString:buffer.baseAddress!)
}