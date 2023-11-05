import cblake2
import RAW

public struct Blake2 {
	public enum Error:Swift.Error {
		case invalidInputLength
		case invalidOutputType(any RAW_staticbuff.Type)
		case initializationError
		case updateError
		case exportError
	}
	fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
		let buffSize = type.RAW_staticbuff_size
		guard buffSize > 0 && buffSize <= 64 else {
			throw Error.invalidOutputType(type)
		}
	}

	/// blake2b hasher implementation.
	public struct B<S:RAW_staticbuff> {
		fileprivate var state = blake2b_state()
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2B_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}
		public init() throws {
			try Blake2.validateOutputLength(S.self)
			guard blake2b_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawVal in
				return try self.update(rawVal)
			}
		}
		public mutating func update<R>(_ rawVal:R) throws where R:RAW_val {
			guard rawVal.RAW_size > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2b_update(&state, rawVal.RAW_data, rawVal.RAW_size) == 0 else {
				throw Error.updateError
			}
		}
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2b_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return S(RAW_size:S.RAW_staticbuff_size, RAW_data:buffer)!
		}
	}

	/// blake2s hasher implementation.
	public struct S<S:RAW_staticbuff> {
		fileprivate var state = blake2s_state()
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2S_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}
		public init() throws {
			try Blake2.validateOutputLength(S.self)
			guard blake2s_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawVal in
				return try self.update(rawVal)
			}
		}
		public mutating func update<R>(_ rawVal:R) throws where R:RAW_val {
			guard rawVal.RAW_size > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2s_update(&state, rawVal.RAW_data, rawVal.RAW_size) == 0 else {
				throw Error.updateError
			}
		}
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2s_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return S(RAW_size:S.RAW_staticbuff_size, RAW_data:buffer)!
		}
	}

	/// blake2bp hasher implementation.
	public struct BP<S:RAW_staticbuff> {
		fileprivate var state = blake2bp_state()
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2B_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}
		public init() throws {
			try Blake2.validateOutputLength(S.self)
			guard blake2bp_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawVal in
				return try self.update(rawVal)
			}
		}
		public mutating func update<R>(_ rawVal:R) throws where R:RAW_val {
			guard rawVal.RAW_size > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2bp_update(&state, rawVal.RAW_data, rawVal.RAW_size) == 0 else {
				throw Error.updateError
			}
		}
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2bp_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return S(RAW_size:S.RAW_staticbuff_size, RAW_data:buffer)!
		}
	}

	/// blake2sp hasher implementation.
	public struct SP<S:RAW_staticbuff> {
		fileprivate var state = blake2sp_state()
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2S_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}
		public init() throws {
			try Blake2.validateOutputLength(S.self)
			guard blake2sp_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawVal in
				return try self.update(rawVal)
			}
		}
		public mutating func update<R>(_ rawVal:R) throws where R:RAW_val {
			guard rawVal.RAW_size > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2sp_update(&state, rawVal.RAW_data, rawVal.RAW_size) == 0 else {
				throw Error.updateError
			}
		}
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2sp_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return S(RAW_size:S.RAW_staticbuff_size, RAW_data:buffer)!
		}
	}

	/// blake2xb hasher implementation.
	public struct XB<S:RAW_staticbuff> {
		fileprivate var state = blake2xb_state()
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 else {
				throw Error.invalidOutputType(type)
			}
		}
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}
		public init() throws {
			try Blake2.validateOutputLength(S.self)
			guard blake2xb_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawVal in
				return try self.update(rawVal)
			}
		}
		public mutating func update<R>(_ rawVal:R) throws where R:RAW_val {
			guard rawVal.RAW_size > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2xb_update(&state, rawVal.RAW_data, rawVal.RAW_size) == 0 else {
				throw Error.updateError
			}
		}
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2xb_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return S(RAW_size:S.RAW_staticbuff_size, RAW_data:buffer)!
		}
	}

	/// blake2xs hasher implementation.
	public struct XS<S:RAW_staticbuff> {
		fileprivate var state = blake2xs_state()
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 else {
				throw Error.invalidOutputType(type)
			}
		}
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}
		public init() throws {
			try Blake2.validateOutputLength(S.self)
			guard blake2xs_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawVal in
				return try self.update(rawVal)
			}
		}
		public mutating func update<R>(_ rawVal:R) throws where R:RAW_val {
			guard rawVal.RAW_size > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2xs_update(&state, rawVal.RAW_data, rawVal.RAW_size) == 0 else {
				throw Error.updateError
			}
		}
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2xs_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return S(RAW_size:S.RAW_staticbuff_size, RAW_data:buffer)!
		}
	}
}