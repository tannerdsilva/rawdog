import cblake2
import RAW

extension blake2b_state:RAW_blake2_state_impl {}

/// blake2b hasher implementation.
public struct B:RAW_blake2_func_impl {
	public static let RAW_blake2_func_impl_exec_init_nokey_f:RAW_blake2_func_impl_exec_init_nokey_t = blake2b_init
	public static let RAW_blake2_func_impl_exec_init_keyed_f:RAW_blake2_func_impl_exec_init_keyed_t = blake2b_init_key
	public static let RAW_blake2_func_impl_exec_update_f:RAW_blake2_func_impl_exec_update_t = blake2b_update
	public static let RAW_blake2_func_impl_exec_finalize_f:RAW_blake2_func_impl_exec_finalize_t = blake2b_final

	/// the state type that this hashing variant uses
	public typealias RAW_blake2_statetype = blake2b_state
}

extension B:RAW_blake2_func_impl_initparam {
	/// the parameter type that this hashing variant uses
	public typealias RAW_blake2_paramtype = blake2b_param

	/// the function that initializes the hasher with a given parameter set.
	public static let RAW_blake2_func_impl_initparam_create_f: RAW_blake2_func_impl_initparam_create_t = blake2b_init_param
}