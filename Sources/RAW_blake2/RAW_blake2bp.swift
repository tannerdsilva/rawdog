import __crawdog_blake2
import RAW
import CRAW

extension __crawdog_blake2bp_state:RAW_blake2_state_impl {}

/// blake2bp hasher implementation.
public struct BP:RAW_blake2_func_impl {
	public static let RAW_blake2_func_impl_exec_init_nokey_f:RAW_blake2_func_impl_exec_init_nokey_t = __crawdog_blake2bp_init
	public static let RAW_blake2_func_impl_exec_init_keyed_f:RAW_blake2_func_impl_exec_init_keyed_t = __crawdog_blake2bp_init_key
	public static let RAW_blake2_func_impl_exec_update_f:RAW_blake2_func_impl_exec_update_t = __crawdog_blake2bp_update
	public static let RAW_blake2_func_impl_exec_finalize_f:RAW_blake2_func_impl_exec_finalize_t = __crawdog_blake2bp_final

	/// the state type that this hashing variant uses
	public typealias RAW_blake2_statetype = __crawdog_blake2bp_state
}