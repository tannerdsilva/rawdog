import RAW

public enum Error:Swift.Error {
	/// general error that is thrown when a function returns false
	case hexDecodeFailed
	/// general error that is thrown when a function returns false
	case hexEncodeFailed
	/// thrown when the hex string is not a valid hex string.
	case invalidHexCharacter(UInt8)
}

public typealias HexValue = Value

extension Value {
	internal init(hexchar indexValue:UInt8) {
		switch indexValue {
		case 0:
			self = .zero
		case 1:
			self = .one
		case 2:
			self = .two
		case 3:
			self = .three
		case 4:
			self = .four
		case 5:
			self = .five
		case 6:
			self = .six
		case 7:
			self = .seven
		case 8:
			self = .eight
		case 9:
			self = .nine

		case 10:
			self = .a
		case 11:
			self = .b
		case 12:
			self = .c
		case 13:
			self = .d
		case 14:
			self = .e
		case 15:
			self = .f

		default: fatalError()
		}
	}
}

extension Value {
	public func asciiValue() -> UInt8 {
		switch self {
		case .zero:
			return 0x30 // ASCII value for '0'
		case .one:
			return 0x31 // ASCII value for '1'
		case .two:
			return 0x32 // ASCII value for '2'
		case .three:
			return 0x33 // ASCII value for '3'
		case .four:
			return 0x34 // ASCII value for '4'
		case .five:
			return 0x35 // ASCII value for '5'
		case .six:
			return 0x36 // ASCII value for '6'
		case .seven:
			return 0x37 // ASCII value for '7'
		case .eight:
			return 0x38 // ASCII value for '8'
		case .nine:
			return 0x39 // ASCII value for '9'
		case .a:
			return 0x61 // ASCII value for 'a'
		case .b:
			return 0x62 // ASCII value for 'b'
		case .c:
			return 0x63 // ASCII value for 'c'
		case .d:
			return 0x64 // ASCII value for 'd'
		case .e:
			return 0x65 // ASCII value for 'e'
		case .f:
			return 0x66 // ASCII value for 'f'
		}
	}
}

extension Value:ExpressibleByExtendedGraphemeClusterLiteral {
	public typealias ExtendedGraphemeClusterLiteralType = Character
	public init(extendedGraphemeClusterLiteral: Character) {
		self = try! Self.init(validate:extendedGraphemeClusterLiteral)
	}
}

extension Value {
	/// initialize a hex value from a character value representing a hex-encoded value.
	/// - throws: `Error.invalidHexCharacter` if the character is not a valid hex character.
	public init(validate char:Character) throws {
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

	/// initialize a hex value from a pre-validated character representing a hex-encoded value.
	/// - WARNING: this initializer does not validate the character. it is the caller's responsibility to ensure that the character is a valid hex character. undefined behavior will result if the character is not a valid hex character.
	init(validated char:Character) {
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

		default: fatalError()
		}
	}

	/// initialize a hex value from an ascii value representing a hex-encoded value.
	/// - throws: `Error.invalidHexCharacter` if the character is not a valid hex character.
	init(validate byte:UInt8) throws {
		switch byte {

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
			throw Error.invalidHexCharacter(byte)
		}
	}

	/// initialize a hex value from a pre-validated ascii value representing a hex-encoded value.
	/// - WARNING: this initializer does not validate the character. it is the caller's responsibility to ensure that the character is a valid hex character. undefined behavior will result if the character is not a valid hex character.
	init(validated byte:UInt8) {
		switch byte {
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
		default: fatalError()
		}
	}
}

/// encode a byte buffer into a hex representation.
public func hex_encode(_ data:UnsafeRawPointer, _ data_size:size_t) -> [Value] {
	// determine the size of the output buffer. this is referenced a few times, so we'll just calculate it once.
	let encodingSize = [Value].encodingSize(forUnencodedByteCount:data_size)

	// assemble the output buffer. we'll use the unsafe initializer to avoid initializing the buffer twice. return the buffer.
	return [Value](unsafeUninitializedCapacity:encodingSize, initializingWith: { valueBuffer, valueCount in
		valueCount = 0
		let byteInputBuffer = UnsafeBufferPointer<UInt8>(start:data.assumingMemoryBound(to:UInt8.self), count:data_size)
		for byte in byteInputBuffer {
			let high = byte >> 4
			let low = byte & 0x0F
			valueBuffer[valueCount] = Value(hexchar:high)
			valueCount += 1
			valueBuffer[valueCount] = Value(hexchar:low)
			valueCount += 1
		}
		valueCount = encodingSize
	})
}


public func hex_decode(encoded:UnsafePointer<Value>, valueCount:size_t) throws -> [UInt8] {
	// compute the length of the input buffer. if it's less than 2, we can't decode it.
	let inputLength:size_t = valueCount
	guard inputLength > 1 else {
		throw Error.hexDecodeFailed
	}
	let outputTheoreticalLength:size_t = [Value].decodedSize(forEncodedByteCount:inputLength)
	let outputBytes = [UInt8](unsafeUninitializedCapacity:outputTheoreticalLength, initializingWith: { outputBuffer, outStrided in
		outStrided = 0
		var inputScan:size_t = 0
		while ((inputLength - inputScan) > 1) {
			defer {
				outStrided += 1
				inputScan += 2
			}

			// read two bytes
			let v1 = encoded[inputScan]
			let v2 = encoded[inputScan + 1]
			
			// write one byte
			outputBuffer[outStrided] = (v1.asciiValue() << 4) | v2.asciiValue()
		}
		assert(inputLength == 0)
	})
	return outputBytes
}

extension [Value] {
	/// returns the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	public static func encodingSize(forUnencodedByteCount byteCount:size_t) -> size_t {
		return byteCount * 2
	}

	/// returns the number of unencoded bytes that would be required to decode the current instance of ``Value`` values.
	public static func decodedSize(forEncodedByteCount byteCount:size_t) -> size_t {
		return byteCount / 2
	}
}