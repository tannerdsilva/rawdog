import Testing
@testable import RAW_mnemonic

func hexToBytes(_ hex: String) -> [UInt8] {
	var bytes = [UInt8]()
	var startIndex = hex.startIndex

	while startIndex < hex.endIndex {
		let endIndex = hex.index(startIndex, offsetBy: 2)
		let byteString = hex[startIndex..<endIndex]
		if let byte = UInt8(byteString, radix: 16) {
			bytes.append(byte)
		}
		startIndex = endIndex
	}

	return bytes
}

struct RAW_mnemonicTests {
	@Suite("EncodeTests")
	struct EncodeTests {
		@Test func testEncode128bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("00000000000000000000000000000000")

			try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				let mnemonic = try Mnemonic.encode(entropyBuffer)
				let mnemonicString = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

				let expectedMnemonic: [String] = mnemonicString.split(separator: " ").map { String($0) }
				
				#expect(mnemonic == expectedMnemonic)
			}
		}
		
		@Test func testEncode256bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("8080808080808080808080808080808080808080808080808080808080808080")
			
			try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				let mnemonic = try Mnemonic.encode(entropyBuffer)
				let mnemonicString = "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless"

				let expectedMnemonic: [String] = mnemonicString.split(separator: " ").map { String($0) }
				
				#expect(mnemonic == expectedMnemonic)
			}
		}
	}
	
	@Suite("DecodeTests")
	struct DecodeTests {
		@Test func testDecode128bit() throws {
			let mnemonicString = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

			let mnemonic: [String] = mnemonicString.split(separator: " ").map { String($0) }
			
			var bytes = [UInt8](repeating: 0, count: 16) // example size
			try bytes.withUnsafeMutableBufferPointer { ptr in
				try Mnemonic.decode(mnemonic, into: ptr.baseAddress!)
			}
			#expect(bytes == hexToBytes("00000000000000000000000000000000"))
		}
		@Test func testDecode256bit() throws {
			let mnemonicString = "letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic avoid letter advice cage absurd amount doctor acoustic bless"

			let mnemonic: [String] = mnemonicString.split(separator: " ").map { String($0) }
			
			var bytes = [UInt8](repeating: 0, count: 32) // example size
			try bytes.withUnsafeMutableBufferPointer { ptr in
				try Mnemonic.decode(mnemonic, into: ptr.baseAddress!)
			}
			#expect(bytes == hexToBytes("8080808080808080808080808080808080808080808080808080808080808080"))
		}
	}
	
	@Suite("Ecode and Decode Tests")
	struct EncodeAndDecodeTests {
		@Test func testRoundTrip128bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("00000000000000000000000000000000")
			
			let mnemonic = try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				return try Mnemonic.encode(entropyBuffer)
			}
			var bytes = [UInt8](repeating: 0, count: 16) // example size
			try bytes.withUnsafeMutableBufferPointer { ptr in
				try Mnemonic.decode(mnemonic, into: ptr.baseAddress!)
			}
			#expect(bytes == entropyBytes)
		}
		
		@Test func testRoundTrip256bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("8080808080808080808080808080808080808080808080808080808080808080")
			
			let mnemonic = try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				return try Mnemonic.encode(entropyBuffer)
			}
			var bytes = [UInt8](repeating: 0, count: 32) // example size
			try bytes.withUnsafeMutableBufferPointer { ptr in
				try Mnemonic.decode(mnemonic, into: ptr.baseAddress!)
			}
			#expect(bytes == entropyBytes)
		}
	}
}
