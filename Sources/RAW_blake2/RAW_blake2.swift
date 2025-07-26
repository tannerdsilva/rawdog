// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_blake2
import RAW

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
	typealias RAW_blake2_func_impl_initparam_create_t = @Sendable (UnsafeMutablePointer<RAW_blake2_statetype>, UnsafePointer<RAW_blake2_paramtype>) -> Int32

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
	typealias RAW_blake2_func_impl_exec_init_nokey_t = @Sendable (UnsafeMutablePointer<RAW_blake2_statetype>?, Int) -> Int32
	/// keyed initialization function type
	typealias RAW_blake2_func_impl_exec_init_keyed_t = @Sendable (UnsafeMutablePointer<RAW_blake2_statetype>?, Int, UnsafeRawPointer?, Int) -> Int32
	/// update function type
	typealias RAW_blake2_func_impl_exec_update_t = @Sendable (UnsafeMutablePointer<RAW_blake2_statetype>?, UnsafeRawPointer?, Int) -> Int32
	/// finalize function type
	typealias RAW_blake2_func_impl_exec_finalize_t = @Sendable (UnsafeMutablePointer<RAW_blake2_statetype>?, UnsafeMutableRawPointer?, Int) -> Int32

	// api functions for hashing function implementations
	/// no-key initialization function
	static var RAW_blake2_func_impl_exec_init_nokey_f:RAW_blake2_func_impl_exec_init_nokey_t { get }
	/// keyed initialization function
	static var RAW_blake2_func_impl_exec_init_keyed_f:RAW_blake2_func_impl_exec_init_keyed_t { get }
	/// update function
	static var RAW_blake2_func_impl_exec_update_f:RAW_blake2_func_impl_exec_update_t { get }
	/// finalize function
	static var RAW_blake2_func_impl_exec_finalize_f:RAW_blake2_func_impl_exec_finalize_t { get }

	// sizes related to the hashing implementation
	/// the output length of the hashing implementation in question.
	static var RAW_blake2_func_impl_outlen:UInt32 { get }
	/// the block size of the hashing implementation in question.
	static var RAW_blake2_func_impl_blocklen:UInt32 { get }

	/// the static output type of the hashing implementation in question.
	associatedtype RAW_blake2_func_impl_outtype:RAW_staticbuff
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
public struct Hasher<H:RAW_blake2_func_impl, RAW_blake2_out_type> {
	/// the hashing variant that this hasher has implemented.
	public typealias RAW_blake2_func_type = H

	/// the output type of the hashing variant that this hasher has implemented.
	public typealias RAW_blake2_out_type = H.RAW_blake2_func_impl_outtype

	/// internal state of the hasher
	internal var state:H.RAW_blake2_statetype

	/// update the hasher with the given raw byte buffer as input.
	public mutating func update(_ input:UnsafeRawBufferPointer) throws {
		try RAW_blake2_func_type.update(state:&state, input_data_ptr:input.baseAddress!, input_data_size:input.count)
	}
	/// update the hasher with the given byte buffer as input.
	public mutating func update(_ input:UnsafeBufferPointer<UInt8>) throws {
		try RAW_blake2_func_type.update(state:&state, input_data_ptr:input.baseAddress!, input_data_size:input.count)
	}
	/// update the hasher with explicit arguments for the raw data pointer and data size
	public mutating func update(_ data:UnsafeRawPointer, count:size_t) throws {
		try RAW_blake2_func_type.update(state:&state, input_data_ptr:data, input_data_size:count)
	}
}

extension Hasher:RAW_hasher where RAW_blake2_out_type:RAW_staticbuff, RAW_blake2_out_type.RAW_staticbuff_storetype == RAW_blake2_func_type.RAW_blake2_func_impl_outtype.RAW_staticbuff_storetype {
	public static var RAW_hasher_blocksize:size_t {
		size_t(H.RAW_blake2_func_impl_blocklen)
	}

	public typealias RAW_hasher_outputtype = RAW_blake2_out_type

	public mutating func finish<O>(into output:inout Optional<O>) throws where O:RAW_staticbuff, O.RAW_staticbuff_storetype == RAW_hasher_outputtype.RAW_staticbuff_storetype {
		if output == nil {
			output = O(RAW_staticbuff: O.RAW_staticbuff_zeroed())
		}
		try output!.RAW_access_staticbuff_mutating { buffer in
			try RAW_blake2_func_type.finalize(state: &state, output_data_ptr: buffer)
		}
	}
}

extension Hasher where RAW_blake2_out_type == UnsafeMutableRawPointer {
	/// initialize the hasher, preparing it for use without a given key value.
	public init(outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&state, output_length:outputLength)
	}
	
	public init<A:RAW_accessible>(key:borrowing A, outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try key.RAW_access { keyPtr in
			try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyPtr.baseAddress!, key_data_size:keyPtr.count, output_length:outputLength)
		}
	}

	public init<A:RAW_accessible>(key:UnsafePointer<A>, outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try key.pointee.RAW_access { keyPtr in
			try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyPtr.baseAddress!, key_data_size:keyPtr.count, output_length:outputLength)
		}
	}
	
	public init(key keyBuffer:UnsafeBufferPointer<UInt8>, outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyBuffer.baseAddress!, key_data_size:keyBuffer.count, output_length:outputLength)
	}
	
	/// finish the hashing process and return the result as a byte array.
	public mutating func finish(into output:UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer {
		try RAW_blake2_func_type.finalize(state:&state, output_data_ptr:output)
		return output
	}
}

extension Hasher {
	// initializers for this struct will vary based on the output type
	public init() throws {
		state = H.RAW_blake2_statetype()
		try H.create(state:&state, output_length:size_t(H.RAW_blake2_func_impl_outlen))
	}

	public mutating func update<A>(_ accessible:borrowing A) throws where A:RAW_accessible {
		try accessible.RAW_access { buffer in
			try update(UnsafeRawBufferPointer(buffer))
		}
	}

	public mutating func update<A>(_ accessible:UnsafePointer<A>) throws where A:RAW_accessible {
		try accessible.pointee.RAW_access { buffer in
			try update(UnsafeRawBufferPointer(buffer))
		}
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
	public init(outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&state, output_length:outputLength)
	}
	
	public init<A:RAW_accessible>(key:borrowing A, outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try key.RAW_access { keyPtr in
			try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyPtr.baseAddress!, key_data_size:keyPtr.count, output_length:outputLength)
		}
	}

	public init<A:RAW_accessible>(key:UnsafePointer<A>, outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try key.pointee.RAW_access { keyPtr in
			try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyPtr.baseAddress!, key_data_size:keyPtr.count, output_length:outputLength)
		}
	}
	
	public init(key keyBuffer:UnsafeBufferPointer<UInt8>, outputLength:consuming size_t) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyBuffer.baseAddress!, key_data_size:keyBuffer.count, output_length:outputLength)
	}
	
	/// finish the hashing process and return the result as a byte array.
	public mutating func finish() throws -> Array<UInt8> {
		return try RAW_blake2_func_type.finalize(state:&state, type:[UInt8].self)
	}
}

extension Hasher where RAW_blake2_out_type:RAW_staticbuff {
	/// initialize the hasher, preparing it for use without a given key value.
	public init() throws {
		var newState = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&newState, output_length:MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size)
		self.state = newState
	}
	
	public init<A:RAW_accessible>(key:borrowing A) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try key.RAW_access { keyPtr in
			try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyPtr.baseAddress!, key_data_size:keyPtr.count, output_length:MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size)
		}
	}

	public init<A:RAW_accessible>(key:UnsafePointer<A>) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try key.pointee.RAW_access { keyPtr in
			try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyPtr.baseAddress!, key_data_size:keyPtr.count, output_length:MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size)
		}
	}

	public init(key keyBuffer:UnsafeBufferPointer<UInt8>) throws {
		state = RAW_blake2_func_type.RAW_blake2_statetype()
		try Self.RAW_blake2_func_type.create(state:&state, key_data_ptr:keyBuffer.baseAddress!, key_data_size:keyBuffer.count, output_length:MemoryLayout<RAW_blake2_out_type.RAW_staticbuff_storetype>.size)
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

extension Hasher where H:RAW_blake2_func_impl_initparam, RAW_blake2_out_type == [UInt8] {
	public init(param:UnsafePointer<H.RAW_blake2_paramtype>) throws {
		var newState = H.RAW_blake2_statetype()
		try H.create(state:&newState, param:param)
		self.init(state:newState)
	}
}