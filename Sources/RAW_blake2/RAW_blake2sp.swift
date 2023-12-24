import cblake2
import RAW
import CRAW

extension blake2sp_state:RAW_blake2_state_impl {}

/// blake2b hasher implementation.
public struct SP:RAW_blake2_func_impl {
	/// the state type that this hashing variant uses
	public typealias RAW_blake2_statetype = blake2sp_state

	/// initialize the hasher, preparing it for use without a given key value.
	public static func create(state:inout RAW_blake2_statetype, outputLength:size_t) throws {
		guard blake2sp_init(&state, outputLength) == 0 else {
			throw Error.initializationError
		}
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	public static func create(state:inout RAW_blake2_statetype, RAW_key_data_ptr:UnsafeRawPointer, RAW_key_size:size_t, outputLength:Int) throws {
		guard blake2sp_init_key(&state, outputLength, RAW_key_data_ptr, RAW_key_size) == 0 else {
			throw Error.initializationError
		}
	}

	/// primary update function for the hasher.
	public static func update(state:inout RAW_blake2_statetype, RAW_data_ptr:UnsafeRawPointer, RAW_size:size_t) throws {
		guard blake2sp_update(&state, RAW_data_ptr, RAW_size) == 0 else {
			throw Error.updateError
		}
	}

	/// finish the hashing process and return the result.
	public static func finalize(state:inout RAW_blake2_statetype, RAW_data_ptr:UnsafeMutableRawPointer) throws {
		guard blake2sp_final(&state, RAW_data_ptr, state.outlen) == 0 else {
			throw Error.exportError
		}
	}
}