/// represents one of the 16 possible values in a hexadecimal number
@frozen public enum Value {

	/// represents the value `0`
	case zero

	/// represents the value `1`
	case one

	/// represents the value `2`
	case two

	/// represents the value `3`
	case three

	/// represents the value `4`
	case four

	/// represents the value `5`
	case five

	/// represents the value `6`
	case six

	/// represents the value `7`
	case seven

	/// represents the value `8`
	case eight

	/// represents the value `9`
	case nine

	/// represents the value `a`
	case a

	/// represents the value `b`
	case b

	/// represents the value `c`
	case c

	/// represents the value `d`
	case d

	/// represents the value `e`
	case e

	/// represents the value `f`
	case f
}

extension Value {
	/// returns a random hex value.
	public static func random() -> Value {
		return Value(hexcharIndexValue:UInt8.random(in:0...15))
	}
}

// character implementations
extension Value {

	/// initialize a hex value from a character value representing a hex-encoded character.
	/// - note: this is a `validate` variant of this initializer, meaning that the function will throw if the character is not a valid hex character.
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
				throw Error.invalidHexEncodingCharacter(char.asciiValue!)
		}
	}

	/// initialize a hex value from a pre-validated character representing a hex-encoded value.
	/// - WARNING: this is a `validated` variant of this initializer, meaning that the function will not throw if the character is not a valid hex character. a fatal error will occur if the character is not a valid hex character.
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

	/// returns the character value of the hex value.
	public func characterValue() -> Character {
		switch self {
			case .zero:
				return "0"
			case .one:
				return "1"
			case .two:
				return "2"
			case .three:
				return "3"
			case .four:
				return "4"
			case .five:
				return "5"
			case .six:
				return "6"
			case .seven:
				return "7"
			case .eight:
				return "8"
			case .nine:
				return "9"
			case .a:
				return "a"
			case .b:
				return "b"
			case .c:
				return "c"
			case .d:
				return "d"
			case .e:
				return "e"
			case .f:
				return "f"
		}
	}
}

// byte implementations
extension Value {
	/// returns the 8 bit ascii representation of this hex value.
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

	/// initialize a hex value from an 8-bit ascii value representing a hex-encoded value.
	/// - throws: `Error.invalidHexEncodingCharacter` if the character is not a valid hex character.
	public init(validate byte:UInt8) throws {
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
				throw Error.invalidHexEncodingCharacter(byte)
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

// index value implementations
extension Value {
	/// initialize a hex value from a character value representing a hex-encoded value (useful for encoding/decoding purposes).
	internal init(hexcharIndexValue indexValue:UInt8) {
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

	/// returns the index value of the hex value (useful for encoding/decoding purposes)
	internal func hexcharIndexValue() -> UInt8 {
		switch self {
			case .zero:
				return 0
			case .one:
				return 1
			case .two:
				return 2
			case .three:
				return 3
			case .four:
				return 4
			case .five:
				return 5
			case .six:
				return 6
			case .seven:
				return 7
			case .eight:
				return 8
			case .nine:
				return 9
			case .a:
				return 10
			case .b:
				return 11
			case .c:
				return 12
			case .d:
				return 13
			case .e:
				return 14
			case .f:
				return 15
		}
	}
}

extension Value:ExpressibleByExtendedGraphemeClusterLiteral {
	public typealias ExtendedGraphemeClusterLiteralType = Character
	public init(extendedGraphemeClusterLiteral: Character) {
		self = try! Self.init(validate:extendedGraphemeClusterLiteral)
	}
}