import XCTest
@testable import RAW

class DataPointersTests: XCTestCase {
	func testDecodeFromTuple() {
		var myTuple:(UInt8, UInt8, UInt8) = (1, 2, 3)
		let decoded = withUnsafePointer(to:&myTuple) { ptr in
			return [UInt8](unsafeUninitializedCapacity:3, initializingWith: { buffer, size in
				memcpy(buffer.baseAddress, ptr, 3)
				size = 3
			})
		}
		XCTAssertEqual(decoded, [0x01, 0x02, 0x03])
	}
}