import cblake2
import RAW
import CRAW

extension blake2s_state:RAW_blake2_state_impl {}

/// blake2s hasher implementation.
public struct S:RAW_blake2_func_impl {
	public static let RAW_blake2_func_impl_exec_init_nokey_f:RAW_blake2_func_impl_exec_init_nokey_t = blake2s_init
	public static let RAW_blake2_func_impl_exec_init_keyed_f:RAW_blake2_func_impl_exec_init_keyed_t = blake2s_init_key
	public static let RAW_blake2_func_impl_exec_update_f:RAW_blake2_func_impl_exec_update_t = blake2s_update
	public static let RAW_blake2_func_impl_exec_finalize_f:RAW_blake2_func_impl_exec_finalize_t = blake2s_final

	/// the state type that this hashing variant uses
	public typealias RAW_blake2_statetype = blake2s_state
}

extension S:RAW_blake2_func_impl_initparam {
	/// the parameter type that this hashing variant uses
	public typealias RAW_blake2_paramtype = blake2s_param

	/// the function that initializes the hasher with a given parameter set.
	public static let RAW_blake2_func_impl_initparam_create_f: RAW_blake2_func_impl_initparam_create_t = blake2s_init_param
}