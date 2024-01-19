public protocol RAW_accessible:RAW_encodable {
	/// allows mutating access to the raw representation of the static buffer type.
	mutating func RAW_access_mutating<R>(_ body:(inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R
}

extension RAW_accessible {
	public mutating func RAW_transcode_copy<T>(to:T.Type, destination:inout T?) where T:RAW_decodable {
		RAW_access_mutating { buff in
			destination = T.init(RAW_accessed:buff)
		}
	}
}
