// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import Testing
@testable import RAW

@RAW_staticbuff(bytes:2)
fileprivate struct _UTF16_CHAR:RAW_encoded_fixedwidthinteger, Sendable {
	#RAW_staticbuff_fixedwidthinteger_type<UInt16>(bigEndian:true)
}

extension rawdog_tests {
	@Suite("StringTests")
	struct StringTests {
		@Test func testRAWEncodeAndDecodeUTF16() {
			var char = _UTF16_CHAR(RAW_native: UInt16(0x0041)) // 'A'
			var bcount:Int = 0
			let encoded = [UInt8](RAW_encodable:&char, byte_count_out:&bcount)
			#expect(bcount == 2)
			#expect(encoded == [0x00, 0x41])
		}
	}
}
