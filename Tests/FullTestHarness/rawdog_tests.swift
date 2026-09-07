// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import Testing
import RAW

@Suite("rawdog_tests",
	.serialized
)
public struct rawdog_tests {
	@RAW_staticbuff(bytes:64)
	internal struct My64:Sendable {}
	@Test("RAW_access :: validate equal pointers") func validateEqualPointersWithinAccesses() throws {
		let key = [UInt8](repeating: 0, count: 64).withUnsafeBytes { My64(RAW_decode: $0)! }
		let leftThing = key.RAW_access_immutable(UnsafeRawBufferPointer.self) { buff in
			return buff
		}
		let rightThing = key.RAW_access_immutable(UnsafeRawBufferPointer.self) { buff in
			return buff
		}
		#expect(leftThing.baseAddress == rightThing.baseAddress)
	}
}