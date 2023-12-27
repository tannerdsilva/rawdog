import cblake2
import RAW
import CRAW

extension blake2b_state:RAW_blake2_state_impl {}

/// blake2b hasher implementation.
public struct B:RAW_blake2_func_impl {
    public static var RAW_blake2_func_impl_exec_init_nokey_f: RAW_blake2_func_impl_exec_init_nokey_t = blake2b_init

	/// the state type that this hashing variant uses
	public typealias RAW_blake2_statetype = blake2b_state

	/// initialize the hasher, preparing it for use without a given key value.
	public static func create(state:inout RAW_blake2_statetype, outputLength:size_t) throws {
		guard blake2b_init(&state, outputLength) == 0 else {
			throw Error.initializationError
		}
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	public static func create(state:inout RAW_blake2_statetype, RAW_key_data_ptr:UnsafeRawPointer, RAW_key_size:size_t, outputLength:Int) throws {
		guard blake2b_init_key(&state, outputLength, RAW_key_data_ptr, RAW_key_size) == 0 else {
			throw Error.initializationError
		}
	}

	/// primary update function for the hasher.
	public static func update(state:inout RAW_blake2_statetype, RAW_val_data_ptr:UnsafeRawPointer, RAW_val_size:size_t) throws {
		guard blake2b_update(&state, RAW_val_data_ptr, RAW_val_size) == 0 else {
			throw Error.updateError
		}
	}

	/// finish the hashing process and return the result.
	public static func finalize(state:inout RAW_blake2_statetype, RAW_val_data_ptr:UnsafeMutableRawPointer) throws {
		guard blake2b_final(&state, RAW_val_data_ptr, state.outlen) == 0 else {
			throw Error.exportError
		}
	}
}

extension B:RAW_blake2_func_impl_initparam {
	/// the parameter type that this hashing variant uses
	public typealias RAW_blake2_paramtype = blake2b_param

	/// initialize the hasher, preparing it for use with a given parameter set.
	public static func create(state:inout RAW_blake2_statetype, param:UnsafePointer<RAW_blake2_paramtype>) throws {
		guard blake2b_init_param(&state, param) == 0 else {
			throw Error.initializationError
		}
	}
}