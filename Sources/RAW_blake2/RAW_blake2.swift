import cblake2
import RAW
import CRAW

/// the error type for blake2 hasher operations.
public enum Error:Swift.Error {
	/// thrown when the output legnth is not valid for the given blake2 implementation.
	case invalidOutputLength(size_t, ClosedRange<size_t>)
	/// thrown when the size of the output buffer does not match the configured output length of the hasher.
	/// - parameter 1: the specified size of the output buffer.
	/// - parameter 2: the previously-configured output length of the hasher.
	case invalidExportLength(size_t, size_t)
	/// thrown when the initialization of the hasher fails.
	case initializationError
	/// thrown when the update of the hasher fails to update its state with the given input.
	case updateError
	/// thrown when the export of the hasher fails to export its state into the given output buffer.
	case exportError
}

/// the protocol that all blake2 state types must conform to. this allows for generic implementations of the blake2 hashing functions.
public protocol RAW_blake2_state_impl {
	/// the currently configured output length of the hasher.
	var outlen:size_t { get }

	/// initialize a new state instance.
	init()
}

/// used to specify the blake2 hashing variants that support initialization with a parameter set.
public protocol RAW_blake2_func_impl_initparam {
	/// the parameter type that a given hashing variant uses.
	associatedtype RAW_blake2_paramtype

	/// the state type that a given hashing variant uses.
	associatedtype RAW_blake2_statetype:RAW_blake2_state_impl

	/// api types for hashing function implementations
	typealias RAW_blake2_func_impl_initparam_create_t = (UnsafeMutablePointer<RAW_blake2_statetype>, UnsafePointer<RAW_blake2_paramtype>) -> Int32

	/// the function that initializes the hasher with a given parameter set.
	static var RAW_blake2_func_impl_initparam_create_f:RAW_blake2_func_impl_initparam_create_t { get }
}

extension RAW_blake2_func_impl_initparam {
	internal static func create(state:UnsafeMutablePointer<RAW_blake2_statetype>, param:UnsafePointer<RAW_blake2_paramtype>) throws {
		guard RAW_blake2_func_impl_initparam_create_f(state, param) == 0 else {
			throw Error.initializationError
		}
	}
}

/// used to specify a type of blake2 hashing function that can be used.
/// implementors include the blake2b and blake2s hashing functions.
public protocol RAW_blake2_func_impl {

	/// the state type that a given hashing variant uses.
	associatedtype RAW_blake2_statetype:RAW_blake2_state_impl

	// api types for hashing function implementations
	/// no-key initialization function type
	typealias RAW_blake2_func_impl_exec_init_nokey_t = (UnsafeMutablePointer<RAW_blake2_statetype>?, Int) -> Int32
	/// keyed initialization function type
	typealias RAW_blake2_func_impl_exec_init_keyed_t = (UnsafeMutablePointer<RAW_blake2_statetype>?, Int, UnsafeRawPointer?, Int) -> Int32
	/// update function type
	typealias RAW_blake2_func_impl_exec_update_t = (UnsafeMutablePointer<RAW_blake2_statetype>?, UnsafeRawPointer?, Int) -> Int32
	/// finalize function type
	typealias RAW_blake2_func_impl_exec_finalize_t = (UnsafeMutablePointer<RAW_blake2_statetype>?, UnsafeMutableRawPointer?, Int) -> Int32

	// api functions for hashing function implementations
	/// no-key initialization function
	static var RAW_blake2_func_impl_exec_init_nokey_f:RAW_blake2_func_impl_exec_init_nokey_t { get }
	/// keyed initialization function
	static var RAW_blake2_func_impl_exec_init_keyed_f:RAW_blake2_func_impl_exec_init_keyed_t { get }
	/// update function
	static var RAW_blake2_func_impl_exec_update_f:RAW_blake2_func_impl_exec_update_t { get }
	/// finalize function
	static var RAW_blake2_func_impl_exec_finalize_f:RAW_blake2_func_impl_exec_finalize_t { get }
}

extension RAW_blake2_func_impl {
	/// initialize the hasher, preparing it for use without a given key value.
	internal static func create(state:UnsafeMutablePointer<RAW_blake2_statetype>?, output_length:size_t) throws {
		guard RAW_blake2_func_impl_exec_init_nokey_f(state, output_length) == 0 else {
			throw Error.initializationError
		}
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	internal static func create(state:UnsafeMutablePointer<RAW_blake2_statetype>?, key_data_ptr:UnsafeRawPointer, key_data_size:size_t, output_length:Int) throws {
		guard RAW_blake2_func_impl_exec_init_keyed_f(state, output_length, key_data_ptr, key_data_size) == 0 else {
			throw Error.initializationError
		}
	}

	/// primary update function for the hasher.
	internal static func update(state:UnsafeMutablePointer<RAW_blake2_statetype>?, input_data_ptr:UnsafeRawPointer, input_data_size:size_t) throws {
		guard RAW_blake2_func_impl_exec_update_f(state, input_data_ptr, input_data_size) == 0 else {
			throw Error.updateError
		}
	}

	/// finish the hashing process and return the result.
	internal static func finalize(state:UnsafeMutablePointer<RAW_blake2_statetype>?, output_data_ptr:UnsafeMutableRawPointer) throws {
		guard RAW_blake2_func_impl_exec_finalize_f(state, output_data_ptr, state!.pointee.outlen) == 0 else {
			throw Error.exportError
		}
	}
}

extension RAW_blake2_func_impl {
	/// finish the hashing process and return the result as a byte array.
	internal static func finalize(state:UnsafeMutablePointer<RAW_blake2_statetype>?, type outType:[UInt8].Type) throws -> [UInt8] {
		let outputLength = state!.pointee.outlen
		return try [UInt8](unsafeUninitializedCapacity:outputLength, initializingWith: { (buffer, initializedCount) in
			try Self.finalize(state:state, output_data_ptr:buffer.baseAddress!)
			initializedCount = outputLength
		})
	}
}

/// main blake2 hasher
public struct Hasher<H:RAW_blake2_func_impl, O> {
	/// the hashing variant that this hasher has implemented.
	public typealias RAW_blake2_func_type = H

	/// the output type of the hashing variant that this hasher has implemented.
	public typealias RAW_blake2_out_type = O

	/// internal state of the hasher
	internal var state:H.RAW_blake2_statetype

	// initializers for this struct will vary based on the output type

	/// update the hasher with the given bytes as input.
	public mutating func update(input_data_ptr:UnsafePointer<UInt8>, input_data_size:size_t) throws {
		try RAW_blake2_func_type.update(state:&state, input_data_ptr:input_data_ptr, input_data_size:input_data_size)
	}

	// finishing processes for this struct will vary based on the output type
}

extension Hasher {
	public mutating func update(_ input:[UInt8]) throws {
		var updateCopy = input
		try update(&updateCopy)
	}
	public mutating func update(_ input:inout [UInt8]) throws {
		try update(input_data_ptr:input, input_data_size:input.count)
	}
}

extension Hasher where O == Array<UInt8> {
	/// finish the hashing process and return the result as a byte array.
	public mutating func finish() throws -> RAW_blake2_out_type {
		return try RAW_blake2_func_type.finalize(state:&state, type:[UInt8].self)
	}
}

extension Hasher where RAW_blake2_out_type:RAW_decodable {
	/// finish the hashing process and return the result as a byte array.
	public mutating func finish() throws -> RAW_blake2_out_type {
		let finalHashedBytes = try RAW_blake2_func_type.finalize(state:&state, type:[UInt8].self)
		return RAW_blake2_out_type(RAW_decode: finalHashedBytes, count:state.outlen)!
	}
}

// implementation for byte array output
extension Hasher where RAW_blake2_out_type == [UInt8] {

	/// initialize the hasher, preparing it for use without a given key value.
	public init(outputLength:size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&state, output_length:outputLength)
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	public init(key_data:UnsafeRawPointer, key_count:size_t, outputLength:size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:key_data, key_data_size:key_count, output_length:outputLength)
	}
}

extension Hasher where RAW_blake2_out_type:RAW_staticbuff {
	/// initialize the hasher, preparing it for use without a given key value.
	public init() throws {
		var newState = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&newState, output_length:MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size)
		self.state = newState
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	public init(key_data:UnsafeRawPointer, key_count:size_t) throws {
		var newState = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&newState, key_data_ptr:key_data, key_data_size:key_count, output_length:MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size)
		self.state = newState
	}

	/// finish the hashing process and return the result as a byte array.
	public mutating func finish() throws -> RAW_blake2_out_type {
		let expectedOutputLength = MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size
		// validate that the output length is correct
		guard expectedOutputLength == state.outlen else {
			throw Error.invalidExportLength(state.outlen, MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size)
		}
		let finalBytes = try RAW_blake2_func_type.finalize(state:&state, type:[UInt8].self)
		return RAW_blake2_out_type(RAW_decode:finalBytes)!
	}
}

extension Hasher where H:RAW_blake2_func_impl_initparam, O == [UInt8] {
	public init(param:UnsafePointer<H.RAW_blake2_paramtype>) throws {
		var newState = H.RAW_blake2_statetype()
		try H.create(state:&newState, param:param)
		self.init(state:newState)
	}
}