/// the protocol that enables comparison of programming objects from raw memory representations.
/// this protocol is expected to have reflecting implementations of the ``Comparable`` and ``Equatable`` protocols, but these are automatically synthesized by the compiler.
public protocol RAW_comparable:Comparable, Equatable {
	/// the static comparable function for this type.
	static func RAW_compare(_ lhs:RAW, _ rhs:RAW) -> Int32
}