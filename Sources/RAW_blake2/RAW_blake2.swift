import cblake2
import RAW
import CRAW

/// umbrella namespace for the blake2 hashing functions.
public struct Blake2 {

	/// the error type for blake2 hasher operations.
	public enum Error:Swift.Error {
		/// thrown when the input length is invalid.
		case invalidInputLength
		/// thrown when the output type is not valid for the given blake2 implementation type.
		case invalidOutputType(any RAW_staticbuff.Type)
		/// thrown when the initialization of the hasher fails.
		case initializationError
		/// thrown when the update of the hasher fails to update its state with the given input.
		case updateError
		/// thrown when the export of the hasher fails to export its state into the given output buffer.
		case exportError
	}

	/// blake2b hasher implementation.
	public struct B<S:RAW_staticbuff> {

		// internal state of the hasher
		fileprivate var state = blake2b_state()

		// validates that the size of the output type is valid for this implementation.
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2B_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}

		/// hashes the given input and returns the result.
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}

		/// initialize the hasher, preparing it for use without a given key value.
		public init() throws {
			try Self.validateOutputLength(S.self)
			guard blake2b_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<R>(key:R) throws where R:RAW_encodable {
			try Self.validateOutputLength(S.self)
			self = try key.asRAW_val({ keyData, keySize in
				return try Self.init(key:keyData, keySize:keySize)
			})
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<V>(key:V) throws where V:RAW_val {
			try Self.validateOutputLength(S.self)
			self = try withUnsafePointer(to:key.RAW_size) { keySizePtr in
				return try Self.init(key:key.RAW_data, keySize:keySizePtr)
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init(key:UnsafeRawPointer, keySize:UnsafePointer<size_t>) throws {
			try Self.validateOutputLength(S.self)
			guard blake2b_init_key(&state, S.RAW_staticbuff_size, key, keySize.pointee) == 0 else {
				throw Error.initializationError
			}
		}

		/// pass bytes (as a raw encodable conformant type) into the hasher to be hashed.
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawDat, rawSiz in
				return try self.update(val(RAW_data:rawDat, RAW_size:rawSiz))
			}
		}

		/// pass bytes (as a raw value conformant type) into the hasher to be hashed.
		public mutating func update<V>(_ rawVal:V) throws where V:RAW_val {
			try withUnsafePointer(to:rawVal.RAW_size) { rawSizePtr in
				return try self.update(bytes:rawVal.RAW_data, size:rawSizePtr)
			}
		}

		/// primary update function for the hasher.
		public mutating func update(bytes:UnsafeRawPointer, size:UnsafePointer<size_t>) throws {
			guard size.pointee > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2b_update(&state, bytes, size.pointee) == 0 else {
				throw Error.updateError
			}
		}

		/// finish the hashing process and return the result.
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2b_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return withUnsafePointer(to:S.RAW_staticbuff_size) { sizePtr in
				return S(RAW_data:buffer, RAW_size:sizePtr)!
			}
		}
	}

	/// blake2s hasher implementation.
	public struct S<S:RAW_staticbuff> {

		// internal state of the hasher
		fileprivate var state = blake2s_state()

		// validates that the size of the output type is valid for this implementation.
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2S_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}

		/// hashes the given input and returns the result.
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}

		/// initialize the hasher, preparing it for use without a given key value.
		public init() throws {
			try Self.validateOutputLength(S.self)
			guard blake2s_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<R>(key:R) throws where R:RAW_encodable {
			try Self.validateOutputLength(S.self)
			self = try key.asRAW_val({ keyData, keySize in
				return try Self.init(key:keyData, keySize:keySize)
			})
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<V>(key:V) throws where V:RAW_val {
			try Self.validateOutputLength(S.self)
			self = try withUnsafePointer(to:key.RAW_size) { keySizePtr in
				return try Self.init(key:key.RAW_data, keySize:keySizePtr)
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init(key:UnsafeRawPointer, keySize:UnsafePointer<size_t>) throws {
			try Self.validateOutputLength(S.self)
			guard blake2s_init_key(&state, S.RAW_staticbuff_size, key, keySize.pointee) == 0 else {
				throw Error.initializationError
			}
		}

		/// pass bytes (as a raw encodable conformant type) into the hasher to be hashed.
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawDat, rawSiz in
				return try self.update(val(RAW_data:rawDat, RAW_size:rawSiz))
			}
		}

		/// pass bytes (as a raw value conformant type) into the hasher to be hashed.
		public mutating func update<V>(_ rawVal:V) throws where V:RAW_val {
			try withUnsafePointer(to:rawVal.RAW_size) { rawSizePtr in
				return try self.update(bytes:rawVal.RAW_data, size:rawSizePtr)
			}
		}

		/// primary update function for the hasher.
		public mutating func update(bytes:UnsafeRawPointer, size:UnsafePointer<size_t>) throws {
			guard size.pointee > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2s_update(&state, bytes, size.pointee) == 0 else {
				throw Error.updateError
			}
		}

		/// finish the hashing process and return the result.
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2s_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return withUnsafePointer(to:S.RAW_staticbuff_size) { sizePtr in
				return S(RAW_data:buffer, RAW_size:sizePtr)!
			}
		}
	}

	/// blake2bp hasher implementation.
	public struct BP<S:RAW_staticbuff> {

		// internal state of the hasher
		fileprivate var state = blake2bp_state()

		// validates that the size of the output type is valid for this implementation.
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2B_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}

		/// hashes the given input and returns the result.
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}

		/// initialize the hasher, preparing it for use.
		public init() throws {
			try Self.validateOutputLength(S.self)
			guard blake2bp_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<R>(key:R) throws where R:RAW_encodable {
			try Self.validateOutputLength(S.self)
			self = try key.asRAW_val({ keyData, keySize in
				return try Self.init(key:keyData, keySize:keySize)
			})
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<V>(key:V) throws where V:RAW_val {
			try Self.validateOutputLength(S.self)
			self = try withUnsafePointer(to:key.RAW_size) { keySizePtr in
				return try Self.init(key:key.RAW_data, keySize:keySizePtr)
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init(key:UnsafeRawPointer, keySize:UnsafePointer<size_t>) throws {
			try Self.validateOutputLength(S.self)
			guard blake2bp_init_key(&state, S.RAW_staticbuff_size, key, keySize.pointee) == 0 else {
				throw Error.initializationError
			}
		}

		/// pass bytes (as a raw encodable conformant type) into the hasher to be hashed.
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawDat, rawSiz in
				return try self.update(val(RAW_data:rawDat, RAW_size:rawSiz))
			}
		}

		/// pass bytes (as a raw value conformant type) into the hasher to be hashed.
		public mutating func update<V>(_ rawVal:V) throws where V:RAW_val {
			try withUnsafePointer(to:rawVal.RAW_size) { rawSizePtr in
				return try self.update(bytes:rawVal.RAW_data, size:rawSizePtr)
			}
		}

		/// primary update function for the hasher.
		public mutating func update(bytes:UnsafeRawPointer, size:UnsafePointer<size_t>) throws {
			guard size.pointee > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2bp_update(&state, bytes, size.pointee) == 0 else {
				throw Error.updateError
			}
		}

		/// finish the hashing process and return the result.
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2bp_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return withUnsafePointer(to:S.RAW_staticbuff_size) { sizePtr in
				return S(RAW_data:buffer, RAW_size:sizePtr)!
			}
		}
	}

	/// blake2sp hasher implementation.
	public struct SP<S:RAW_staticbuff> {

		// internal state of the hasher
		fileprivate var state = blake2sp_state()

		// validates that the size of the output type is valid for this implementation.
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 && buffSize <= BLAKE2S_OUTBYTES.rawValue else {
				throw Error.invalidOutputType(type)
			}
		}

		/// hashes the given input and returns the result.
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}

		/// initialize the hasher, preparing it for use.
		public init() throws {
			try Self.validateOutputLength(S.self)
			guard blake2sp_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<R>(key:R) throws where R:RAW_encodable {
			try Self.validateOutputLength(S.self)
			self = try key.asRAW_val({ keyData, keySize in
				return try Self.init(key:keyData, keySize:keySize)
			})
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<V>(key:V) throws where V:RAW_val {
			try Self.validateOutputLength(S.self)
			self = try withUnsafePointer(to:key.RAW_size) { keySizePtr in
				return try Self.init(key:key.RAW_data, keySize:keySizePtr)
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init(key:UnsafeRawPointer, keySize:UnsafePointer<size_t>) throws {
			try Self.validateOutputLength(S.self)
			guard blake2sp_init_key(&state, S.RAW_staticbuff_size, key, keySize.pointee) == 0 else {
				throw Error.initializationError
			}
		}

		/// pass bytes (as a raw encodable conformant type) into the hasher to be hashed.
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawDat, rawSiz in
				return try self.update(val(RAW_data:rawDat, RAW_size:rawSiz))
			}
		}

		/// pass bytes (as a raw value conformant type) into the hasher to be hashed.
		public mutating func update<V>(_ rawVal:V) throws where V:RAW_val {
			try withUnsafePointer(to:rawVal.RAW_size) { rawSizePtr in
				return try self.update(bytes:rawVal.RAW_data, size:rawSizePtr)
			}
		}

		/// primary update function for the hasher.
		public mutating func update(bytes:UnsafeRawPointer, size:UnsafePointer<size_t>) throws {
			guard size.pointee > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2sp_update(&state, bytes, size.pointee) == 0 else {
				throw Error.updateError
			}
		}

		/// finish the hashing process and return the result.
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2sp_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return withUnsafePointer(to:S.RAW_staticbuff_size) { sizePtr in
				return S(RAW_data:buffer, RAW_size:sizePtr)!
			}
		}
	}

	/// blake2xb hasher implementation.
	public struct XB<S:RAW_staticbuff> {

		/// internal state of the hasher
		fileprivate var state = blake2xb_state()

		/// validates that the size of the output type is valid for this implementation.
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 else {
				throw Error.invalidOutputType(type)
			}
		}

		/// hashes the given input and returns the result.
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}

		/// initialize the hasher, preparing it for use.
		public init() throws {
			try Self.validateOutputLength(S.self)
			guard blake2xb_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<R>(key:R) throws where R:RAW_encodable {
			try Self.validateOutputLength(S.self)
			self = try key.asRAW_val({ keyData, keySize in
				return try Self.init(key:keyData, keySize:keySize)
			})
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<V>(key:V) throws where V:RAW_val {
			try Self.validateOutputLength(S.self)
			self = try withUnsafePointer(to:key.RAW_size) { keySizePtr in
				return try Self.init(key:key.RAW_data, keySize:keySizePtr)
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init(key:UnsafeRawPointer, keySize:UnsafePointer<size_t>) throws {
			try Self.validateOutputLength(S.self)
			guard blake2xb_init_key(&state, S.RAW_staticbuff_size, key, keySize.pointee) == 0 else {
				throw Error.initializationError
			}
		}

		/// pass bytes (as a raw encodable conformant type) into the hasher to be hashed.
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawDat, rawSiz in
				return try self.update(val(RAW_data:rawDat, RAW_size:rawSiz))
			}
		}

		/// pass bytes (as a raw value conformant type) into the hasher to be hashed.
		public mutating func update<V>(_ rawVal:V) throws where V:RAW_val {
			try withUnsafePointer(to:rawVal.RAW_size) { rawSizePtr in
				return try self.update(bytes:rawVal.RAW_data, size:rawSizePtr)
			}
		}

		/// primary update function for the hasher.
		public mutating func update(bytes:UnsafeRawPointer, size:UnsafePointer<size_t>) throws {
			guard size.pointee > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2xb_update(&state, bytes, size.pointee) == 0 else {
				throw Error.updateError
			}
		}

		/// finish the hashing process and return the result.
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2xb_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return withUnsafePointer(to:S.RAW_staticbuff_size) { sizePtr in
				return S(RAW_data:buffer, RAW_size:sizePtr)!
			}
		}
	}

	/// blake2xs hasher implementation.
	public struct XS<S:RAW_staticbuff> {

		// internal state of the hasher
		fileprivate var state = blake2xs_state()

		// validates that the size of the output type is valid for this implementation.
		fileprivate static func validateOutputLength(_ type:any RAW_staticbuff.Type) throws {
			let buffSize = type.RAW_staticbuff_size
			guard buffSize > 0 else {
				throw Error.invalidOutputType(type)
			}
		}

		/// hashes the given input and returns the result.
		public static func hash<R>(_ input:R) throws -> S where R:RAW_encodable {
			var hasher = try Self<S>()
			try hasher.update(input)
			return try hasher.finalize()
		}

		/// initialize the hasher, preparing it for use.
		public init() throws {
			try Self.validateOutputLength(S.self)
			guard blake2xs_init(&state, S.RAW_staticbuff_size) == 0 else {
				throw Error.initializationError
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<R>(key:R) throws where R:RAW_encodable {
			try Self.validateOutputLength(S.self)
			self = try key.asRAW_val({ keyData, keySize in
				return try Self.init(key:keyData, keySize:keySize)
			})
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init<V>(key:V) throws where V:RAW_val {
			try Self.validateOutputLength(S.self)
			self = try withUnsafePointer(to:key.RAW_size) { keySizePtr in
				return try Self.init(key:key.RAW_data, keySize:keySizePtr)
			}
		}

		/// initialize the hasher, preparing it for use with a specified key value.
		public init(key:UnsafeRawPointer, keySize:UnsafePointer<size_t>) throws {
			try Self.validateOutputLength(S.self)
			guard blake2xs_init_key(&state, S.RAW_staticbuff_size, key, keySize.pointee) == 0 else {
				throw Error.initializationError
			}
		}

		/// pass bytes (as a raw encodable conformant type) into the hasher to be hashed.
		public mutating func update<R>(_ input:R) throws where R:RAW_encodable {
			try input.asRAW_val { rawDat, rawSiz in
				return try self.update(val(RAW_data:rawDat, RAW_size:rawSiz))
			}
		}

		/// pass bytes (as a raw value conformant type) into the hasher to be hashed.
		public mutating func update<V>(_ rawVal:V) throws where V:RAW_val {
			try withUnsafePointer(to:rawVal.RAW_size) { rawSizePtr in
				return try self.update(bytes:rawVal.RAW_data, size:rawSizePtr)
			}
		}

		/// primary update function for the hasher.
		public mutating func update(bytes:UnsafeRawPointer, size:UnsafePointer<size_t>) throws {
			guard size.pointee > 0 else {
				throw Error.invalidInputLength
			}
			guard blake2xs_update(&state, bytes, size.pointee) == 0 else {
				throw Error.updateError
			}
		}

		/// finish the hashing process and return the result.
		public mutating func finalize() throws -> S {
			let buffer = malloc(S.RAW_staticbuff_size)!
			defer {
				free(buffer)
			}
			guard blake2xs_final(&state, buffer, S.RAW_staticbuff_size) == 0 else {
				throw Error.exportError
			}
			return withUnsafePointer(to:S.RAW_staticbuff_size) { sizePtr in
				return S(RAW_data:buffer, RAW_size:sizePtr)!
			}
		}
	}
}