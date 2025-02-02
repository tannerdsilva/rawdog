// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import __crawdog_blake2
import RAW

extension __crawdog_blake2sp_state:RAW_blake2_state_impl {}

/// blake2b hasher implementation.
public struct SP:RAW_blake2_func_impl {

	@RAW_staticbuff(bytes:32)
	public struct Hash:Sendable {}

	/// the state type that this hashing variant uses
	public typealias RAW_blake2_statetype = __crawdog_blake2sp_state

	public static nonisolated(unsafe) let RAW_blake2_func_impl_exec_init_nokey_f:RAW_blake2_func_impl_exec_init_nokey_t = __crawdog_blake2sp_init
	public static nonisolated(unsafe) let RAW_blake2_func_impl_exec_init_keyed_f:RAW_blake2_func_impl_exec_init_keyed_t = __crawdog_blake2sp_init_key
	public static nonisolated(unsafe) let RAW_blake2_func_impl_exec_update_f:RAW_blake2_func_impl_exec_update_t = __crawdog_blake2sp_update
	public static nonisolated(unsafe) let RAW_blake2_func_impl_exec_finalize_f:RAW_blake2_func_impl_exec_finalize_t = __crawdog_blake2sp_final

	public static let RAW_blake2_func_impl_blocklen = __CRAWDOG_BLAKE2S_BLOCKBYTES.rawValue
	public static let RAW_blake2_func_impl_outlen = __CRAWDOG_BLAKE2S_OUTBYTES.rawValue

	public typealias RAW_blake2_func_impl_outtype = Hash
}