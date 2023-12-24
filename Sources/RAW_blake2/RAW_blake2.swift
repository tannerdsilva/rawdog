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

	/// initialize the hasher, preparing it for use without a given key value.
	static func create(state:inout RAW_blake2_statetype, param:UnsafePointer<RAW_blake2_paramtype>) throws
}

/// used to specify a type of blake2 hashing function that can be used.
public protocol RAW_blake2_func_impl {

	/// the state type that a given hashing variant uses.
	associatedtype RAW_blake2_statetype:RAW_blake2_state_impl

	// required create implementations.
	/// initialize the hasher, preparing it for use without a given key value.
	static func create(state:inout RAW_blake2_statetype, outputLength:size_t) throws
	/// initialize the hasher, preparing it for use with a specified key value.
	static func create(state:inout RAW_blake2_statetype, RAW_key_data_ptr:UnsafeRawPointer, RAW_key_size:size_t, outputLength:size_t) throws

	// required update implementation.
	/// primary update function for the hasher.
	static func update(state:inout RAW_blake2_statetype, RAW_data_ptr:UnsafeRawPointer, RAW_size:size_t) throws
	
	// required finalize implementation.
	/// finish the hashing process and return the result.
	/// - parameter state: the state of the hasher.
	/// - parameter data_out: the output buffer to write the result into.
	static func finalize(state:inout RAW_blake2_statetype, RAW_data_ptr:UnsafeMutableRawPointer) throws
}

extension RAW_blake2_func_impl {

	/// finish the hashing process and return the result as a byte array.
	internal static func finalize(state:inout RAW_blake2_statetype, to outType:[UInt8].Type) throws -> [UInt8] {
		try [UInt8](unsafeUninitializedCapacity:state.outlen, initializingWith: { (buffer, initializedCount) in
			try Self.finalize(state:&state, RAW_data_ptr:buffer.baseAddress!)
			initializedCount = state.outlen
		})
	}
}

/// main blake2 hasher
public struct Hasher<H:RAW_blake2_func_impl, O:RAW_decodable> {
	/// the hashing variant that this hasher has implemented.
	public typealias RAW_blake2_func_type = H

	/// the output type of the hashing variant that this hasher has implemented.
	public typealias RAW_blake2_out_type = O

	/// internal state of the hasher
	internal var state:H.RAW_blake2_statetype

	/// update the hasher with the given bytes as input.
	public mutating func update(RAW_data:UnsafeRawPointer, RAW_size:size_t) throws {
		try RAW_blake2_func_type.update(state:&state, RAW_data_ptr:RAW_data, RAW_size:RAW_size)
	}

	/// finish the hashing process and return the result as a byte array.
	public mutating func finish() throws -> RAW_blake2_out_type {
		let finalHashedBytes = try RAW_blake2_func_type.finalize(state:&state, to:[UInt8].self)
		var i = 0
		
		RAW_blake2_out_type(RAW_decode: finalHashedBytes)
	}
}

// update convenience functions for RAW_val and RAW_encodable
extension Hasher {
	/// update the hasher with the given raw buffer representation as input.
	public mutating func update<R>(_ bytes:R) throws where R:RAW_val {
		try self.update(RAW_data:bytes.RAW_data, RAW_size:bytes.RAW_size)
	}

	/// update the hasher with the given raw buffer representation as input.
	public mutating func update<R>(_ bytes:R) throws where R:RAW_encodable {
		try bytes.asRAW_val({ byte_buff, buff_size in
			try self.update(RAW_data:byte_buff, RAW_size:buff_size.pointee)
		})
	}
}

// implementation for byte array output
extension Hasher where RAW_blake2_out_type == [UInt8] {
	/// finish the hashing process and return the result as a byte array.
	public mutating func finish() throws -> [UInt8] {
		return try RAW_blake2_func_type.finalize(state:&self.state, to:[UInt8].self)
	}

	/// initialize the hasher, preparing it for use without a given key value.
	public init(outputLength:size_t) throws {
		var newState = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&newState, outputLength:outputLength)
		self.state = newState
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	public init(key:UnsafeRawPointer, keySize:size_t, outputLength:size_t) throws {
		var newState = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&newState, RAW_key_data_ptr:key, RAW_key_size:keySize, outputLength:outputLength)
		self.state = newState
	}
}

extension Hasher where RAW_blake2_out_type:RAW_staticbuff {
	/// initialize the hasher, preparing it for use without a given key value.
	public init() throws {
		var newState = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&newState, outputLength:RAW_blake2_out_type.RAW_staticbuff_size)
		self.state = newState
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	public init(key:UnsafeRawPointer, keySize:size_t) throws {
		var newState = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&newState, RAW_key_data:key, RAW_key_size:keySize, outputLength:RAW_blake2_out_type.RAW_staticbuff_size)
		self.state = newState
	}

	/// finish the hashing process and return the result as a byte array.
	public mutating func finish() throws -> RAW_blake2_out_type {
		// validate that the output length is correct
		guard RAW_blake2_out_type.RAW_staticbuff_size == state.outlen else {
			throw Error.invalidExportLength(state.outlen, RAW_blake2_out_type.RAW_staticbuff_size)
		}
		let finalBytes = try RAW_blake2_func_type.finalize(state:&state, to:[UInt8].self)
		return RAW_blake2_out_type(finalBytes)!
	}
}

extension Hasher where H:RAW_blake2_func_impl_initparam, O == [UInt8] {
	public init(param:UnsafePointer<H.RAW_blake2_paramtype>) throws {
		var newState = H.RAW_blake2_statetype()
		try H.create(state:&newState, param:param)
		self.init(state:newState)
	}
}
