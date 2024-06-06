// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
public protocol RAW_accessible:RAW_encodable {
	/// allows for non-mutating access to the raw representation of the instance.
	borrowing func RAW_access<R>(_ body:(UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R
	/// allows for mutating access to the raw representation of the instance.
	mutating func RAW_access_mutating<R>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R
}

extension RAW_accessible {
	public borrowing func RAW_encode(count:inout size_t) {
		RAW_access { buffer in
			count = buffer.count
		}
	}
	public borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
		return RAW_access { buffer in
			_ = RAW_memcpy(dest, buffer.baseAddress!, buffer.count)
			return dest + buffer.count
		}
	}
}