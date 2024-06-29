// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_blake2
import RAW
import CRAW

extension __crawdog_blake2s_state:RAW_blake2_state_impl {}

/// blake2s hasher implementation.
public struct S:RAW_blake2_func_impl {

	@RAW_staticbuff(bytes:32)
	public struct Hash:Sendable {}

	public static let RAW_blake2_func_impl_exec_init_nokey_f:RAW_blake2_func_impl_exec_init_nokey_t = __crawdog_blake2s_init
	public static let RAW_blake2_func_impl_exec_init_keyed_f:RAW_blake2_func_impl_exec_init_keyed_t = __crawdog_blake2s_init_key
	public static let RAW_blake2_func_impl_exec_update_f:RAW_blake2_func_impl_exec_update_t = __crawdog_blake2s_update
	public static let RAW_blake2_func_impl_exec_finalize_f:RAW_blake2_func_impl_exec_finalize_t = __crawdog_blake2s_final

	/// the state type that this hashing variant uses
	public typealias RAW_blake2_statetype = __crawdog_blake2s_state

	public static let RAW_blake2_func_impl_blocklen = __CRAWDOG_BLAKE2S_BLOCKBYTES.rawValue
	public static let RAW_blake2_func_impl_outlen = __CRAWDOG_BLAKE2S_OUTBYTES.rawValue

	public typealias RAW_blake2_func_impl_outtype = Hash
}

extension S:RAW_blake2_func_impl_initparam {
	/// the parameter type that this hashing variant uses
	public typealias RAW_blake2_paramtype = __crawdog_blake2s_param

	/// the function that initializes the hasher with a given parameter set.
	public static let RAW_blake2_func_impl_initparam_create_f: RAW_blake2_func_impl_initparam_create_t = __crawdog_blake2s_init_param
}