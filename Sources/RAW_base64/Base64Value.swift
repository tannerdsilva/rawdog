// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
/// represents one of the 64 possible base64 encoding values
@frozen public enum Value {
	// uppercase alphas (26 values)
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
	
	// lowercase alphas (26 values)
	case a
	case b
	case c
	case d
	case e
	case f
	case g
	case h
	case i
	case j
	case k
	case l
	case m
	case n
	case o
	case p
	case q
	case r
	case s
	case t
	case u
	case v
	case w
	case x
	case y
	case z
	
	// numerical bytes (10 values)
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
	
	// special bytes (2 values)
	case plus
	case slash
}

extension Value {
	/// returns a random base64 value.
	public static func random() -> Self {
		return Self(indexValue:UInt8.random(in:0..<64))
	}
}

extension Value {
	internal func indexValue() -> UInt8 {
		switch self {
			// uppercase letters
			case .A: return 0
			case .B: return 1
			case .C: return 2
			case .D: return 3
			case .E: return 4
			case .F: return 5
			case .G: return 6
			case .H: return 7
			case .I: return 8
			case .J: return 9
			case .K: return 10
			case .L: return 11
			case .M: return 12
			case .N: return 13
			case .O: return 14
			case .P: return 15
			case .Q: return 16
			case .R: return 17
			case .S: return 18
			case .T: return 19
			case .U: return 20
			case .V: return 21
			case .W: return 22
			case .X: return 23
			case .Y: return 24
			case .Z: return 25

			// lowercase letters
			case .a: return 26
			case .b: return 27
			case .c: return 28
			case .d: return 29
			case .e: return 30
			case .f: return 31
			case .g: return 32
			case .h: return 33
			case .i: return 34
			case .j: return 35
			case .k: return 36
			case .l: return 37
			case .m: return 38
			case .n: return 39
			case .o: return 40
			case .p: return 41
			case .q: return 42
			case .r: return 43
			case .s: return 44
			case .t: return 45
			case .u: return 46
			case .v: return 47
			case .w: return 48
			case .x: return 49
			case .y: return 50
			case .z: return 51

			// digits 0-9
			case .zero: return 52
			case .one: return 53
			case .two: return 54
			case .three: return 55
			case .four: return 56
			case .five: return 57
			case .six: return 58
			case .seven: return 59
			case .eight: return 60
			case .nine: return 61

			// special bytes
			case .plus: return 62
			case .slash: return 63
		}
	}

	internal init(indexValue index:UInt8) {
		switch index {
			// uppercase letters
			case 0: self = .A
			case 1: self = .B
			case 2: self = .C
			case 3: self = .D
			case 4: self = .E
			case 5: self = .F
			case 6: self = .G
			case 7: self = .H
			case 8: self = .I
			case 9: self = .J
			case 10: self = .K
			case 11: self = .L
			case 12: self = .M
			case 13: self = .N
			case 14: self = .O
			case 15: self = .P
			case 16: self = .Q
			case 17: self = .R
			case 18: self = .S
			case 19: self = .T
			case 20: self = .U
			case 21: self = .V
			case 22: self = .W
			case 23: self = .X
			case 24: self = .Y
			case 25: self = .Z

			// lowercase letters
			case 26: self = .a
			case 27: self = .b
			case 28: self = .c
			case 29: self = .d
			case 30: self = .e
			case 31: self = .f
			case 32: self = .g
			case 33: self = .h
			case 34: self = .i
			case 35: self = .j
			case 36: self = .k
			case 37: self = .l
			case 38: self = .m
			case 39: self = .n
			case 40: self = .o
			case 41: self = .p
			case 42: self = .q
			case 43: self = .r
			case 44: self = .s
			case 45: self = .t
			case 46: self = .u
			case 47: self = .v
			case 48: self = .w
			case 49: self = .x
			case 50: self = .y
			case 51: self = .z

			// digits 0-9
			case 52: self = .zero
			case 53: self = .one
			case 54: self = .two
			case 55: self = .three
			case 56: self = .four
			case 57: self = .five
			case 58: self = .six
			case 59: self = .seven
			case 60: self = .eight
			case 61: self = .nine

			// special characters
			case 62: self = .plus
			case 63: self = .slash

			default: fatalError()
		}
	}
}

extension Value {
	public init(validate characterValue:Character) throws {
		switch characterValue {
			// uc
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

			// lc
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

			// numbers
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

			// symbols
			case "+": self = .plus
			case "/": self = .slash
			default: throw Error.invalidBase64EncodingCharacter(characterValue)
		}
	}

	public func characterValue() -> Character {
		switch self {
			// uc
			case .A: return "A"
			case .B: return "B"
			case .C: return "C"
			case .D: return "D"
			case .E: return "E"
			case .F: return "F"
			case .G: return "G"
			case .H: return "H"
			case .I: return "I"
			case .J: return "J"
			case .K: return "K"
			case .L: return "L"
			case .M: return "M"
			case .N: return "N"
			case .O: return "O"
			case .P: return "P"
			case .Q: return "Q"
			case .R: return "R"
			case .S: return "S"
			case .T: return "T"
			case .U: return "U"
			case .V: return "V"
			case .W: return "W"
			case .X: return "X"
			case .Y: return "Y"
			case .Z: return "Z"

			// lc
			case .a: return "a"
			case .b: return "b"
			case .c: return "c"
			case .d: return "d"
			case .e: return "e"
			case .f: return "f"
			case .g: return "g"
			case .h: return "h"
			case .i: return "i"
			case .j: return "j"
			case .k: return "k"
			case .l: return "l"
			case .m: return "m"
			case .n: return "n"
			case .o: return "o"
			case .p: return "p"
			case .q: return "q"
			case .r: return "r"
			case .s: return "s"
			case .t: return "t"
			case .u: return "u"
			case .v: return "v"
			case .w: return "w"
			case .x: return "x"
			case .y: return "y"
			case .z: return "z"

			// numbers
			case .zero: return "0"
			case .one: return "1"
			case .two: return "2"
			case .three: return "3"
			case .four: return "4"
			case .five: return "5"
			case .six: return "6"
			case .seven: return "7"
			case .eight: return "8"
			case .nine: return "9"

			// symbols
			case .plus: return "+"
			case .slash: return "/"
		}
	}
}

// MARK: ascii uint8 extensions
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
				// uc
				case 0x41: self = .A
				case 0x42: self = .B
				case 0x43: self = .C
				case 0x44: self = .D
				case 0x45: self = .E
				case 0x46: self = .F
				case 0x47: self = .G
				case 0x48: self = .H
				case 0x49: self = .I
				case 0x4A: self = .J
				case 0x4B: self = .K
				case 0x4C: self = .L
				case 0x4D: self = .M
				case 0x4E: self = .N
				case 0x4F: self = .O
				case 0x50: self = .P
				case 0x51: self = .Q
				case 0x52: self = .R
				case 0x53: self = .S
				case 0x54: self = .T
				case 0x55: self = .U
				case 0x56: self = .V
				case 0x57: self = .W
				case 0x58: self = .X
				case 0x59: self = .Y
				case 0x5A: self = .Z

				// lc:
				case 0x61: self = .a
				case 0x62: self = .b
				case 0x63: self = .c
				case 0x64: self = .d
				case 0x65: self = .e
				case 0x66: self = .f
				case 0x67: self = .g
				case 0x68: self = .h
				case 0x69: self = .i
				case 0x6A: self = .j
				case 0x6B: self = .k
				case 0x6C: self = .l
				case 0x6D: self = .m
				case 0x6E: self = .n
				case 0x6F: self = .o
				case 0x70: self = .p
				case 0x71: self = .q
				case 0x72: self = .r
				case 0x73: self = .s
				case 0x74: self = .t
				case 0x75: self = .u
				case 0x76: self = .v
				case 0x77: self = .w
				case 0x78: self = .x
				case 0x79: self = .y
				case 0x7A: self = .z

				// number
				case 0x30: self = .zero
				case 0x31: self = .one
				case 0x32: self = .two
				case 0x33: self = .three
				case 0x34: self = .four
				case 0x35: self = .five
				case 0x36: self = .six
				case 0x37: self = .seven
				case 0x38: self = .eight
				case 0x39: self = .nine

				// symbols
				case 0x2B: self = .plus
				case 0x2F: self = .slash

				default: fatalError()
			}
	}

	public init(validate asciiValue:UInt8) throws {
		switch asciiValue {
			case 0x41: self = .A
			case 0x42: self = .B
			case 0x43: self = .C
			case 0x44: self = .D
			case 0x45: self = .E
			case 0x46: self = .F
			case 0x47: self = .G
			case 0x48: self = .H
			case 0x49: self = .I
			case 0x4A: self = .J
			case 0x4B: self = .K
			case 0x4C: self = .L
			case 0x4D: self = .M
			case 0x4E: self = .N
			case 0x4F: self = .O
			case 0x50: self = .P
			case 0x51: self = .Q
			case 0x52: self = .R
			case 0x53: self = .S
			case 0x54: self = .T
			case 0x55: self = .U
			case 0x56: self = .V
			case 0x57: self = .W
			case 0x58: self = .X
			case 0x59: self = .Y
			case 0x5A: self = .Z
			case 0x61: self = .a
			case 0x62: self = .b
			case 0x63: self = .c
			case 0x64: self = .d
			case 0x65: self = .e
			case 0x66: self = .f
			case 0x67: self = .g
			case 0x68: self = .h
			case 0x69: self = .i
			case 0x6A: self = .j
			case 0x6B: self = .k
			case 0x6C: self = .l
			case 0x6D: self = .m
			case 0x6E: self = .n
			case 0x6F: self = .o
			case 0x70: self = .p
			case 0x71: self = .q
			case 0x72: self = .r
			case 0x73: self = .s
			case 0x74: self = .t
			case 0x75: self = .u
			case 0x76: self = .v
			case 0x77: self = .w
			case 0x78: self = .x
			case 0x79: self = .y
			case 0x7A: self = .z
			case 0x30: self = .zero
			case 0x31: self = .one
			case 0x32: self = .two
			case 0x33: self = .three
			case 0x34: self = .four
			case 0x35: self = .five
			case 0x36: self = .six
			case 0x37: self = .seven
			case 0x38: self = .eight
			case 0x39: self = .nine
			case 0x2B: self = .plus
			case 0x2F: self = .slash
			default: throw Error.invalidBase64EncodingCharacter(Character(UnicodeScalar(asciiValue)))
		}
	}
}

extension Value:Equatable, Hashable {
	/// hash the value.	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(indexValue())
	}

	/// compare two values for equality.
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
			case (.zero, .zero): return true
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

extension Value:CustomStringConvertible {
	/// get the string representation of this base64 value.
	public var description:String {
		return "\(String(characterValue()))"
	}
}

// character literal impl
extension Value:ExpressibleByExtendedGraphemeClusterLiteral {
	public typealias ExtendedGraphemeClusterLiteralType = Character

	/// initialize a base64 value from a character literal.
	public init(extendedGraphemeClusterLiteral:Character) {
		self = try! Self.init(validate:extendedGraphemeClusterLiteral)
	}
}