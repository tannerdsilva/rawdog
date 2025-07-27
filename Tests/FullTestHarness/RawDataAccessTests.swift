// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import Testing
@testable import RAW
import func Foundation.memcpy

extension rawdog_tests {
	@Suite("Library & language fundamentals")
	struct DataPointersTests {
		@Test("DataPointerTests :: decode from tuple")
		func testDecodeFromTuple() {
			var myTuple:(UInt8, UInt8, UInt8) = (1, 2, 3)
			let decoded = withUnsafePointer(to:&myTuple) { ptr in
				return [UInt8](unsafeUninitializedCapacity:3, initializingWith: { buffer, size in
					memcpy(buffer.baseAddress!, ptr, 3)
					size = 3
				})
			}
			#expect(decoded == [0x01, 0x02, 0x03])
		}
	}
}