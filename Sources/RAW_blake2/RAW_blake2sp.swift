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
		guard outputLength <= BLAKE2S_OUTBYTES.rawValue && outputLength > 0 else {
			throw Error.invalidOutputLength(outputLength, 1...size_t(BLAKE2S_OUTBYTES.rawValue))
		}
		guard blake2sp_init(&state, outputLength) == 0 else {
			throw Error.initializationError
		}
	}

	/// initialize the hasher, preparing it for use with a specified key value.
	public static func create(state:inout RAW_blake2_statetype, RAW_key_data:UnsafeRawPointer, RAW_key_size:size_t, outputLength:Int) throws {
		guard outputLength <= BLAKE2S_OUTBYTES.rawValue && outputLength > 0 else {
			throw Error.invalidOutputLength(outputLength, 1...size_t(BLAKE2S_OUTBYTES.rawValue))
		}
		guard blake2sp_init_key(&state, outputLength, RAW_key_data, RAW_key_size) == 0 else {
			throw Error.initializationError
		}
	}

	/// primary update function for the hasher.
	public static func update(state:inout RAW_blake2_statetype, RAW_data:UnsafeRawPointer, RAW_size:size_t) throws {
		guard blake2sp_update(&state, RAW_data, RAW_size) == 0 else {
			throw Error.updateError
		}
	}

	/// finish the hashing process and return the result.
	public static func finalize(state:inout RAW_blake2_statetype, RAW_data:UnsafeMutableRawPointer) throws {
		guard blake2sp_final(&state, RAW_data, state.outlen) == 0 else {
			throw Error.exportError
		}
	}
}