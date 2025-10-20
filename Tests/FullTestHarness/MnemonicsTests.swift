import Testing
@testable import RAW_mnemonic

fileprivate func hexToBytes(_ hex: String) -> [UInt8] {
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
		@Test func testEncode192bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f")
			
			try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				let mnemonic = try Mnemonic.encode(entropyBuffer)
				let mnemonicString = "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will"

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
		@Test func testDecode192bit() throws {
			let mnemonicString = "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will"

			let mnemonic: [String] = mnemonicString.split(separator: " ").map { String($0) }
			
			var bytes = [UInt8](repeating: 0, count: 24) // example size
			try bytes.withUnsafeMutableBufferPointer { ptr in
				try Mnemonic.decode(mnemonic, into: ptr.baseAddress!)
			}
			#expect(bytes == hexToBytes("7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f"))
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
		@Test func testRoundTrip160bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("7d8a3c6bfa1e42cf9b5d84e6a7c0912fbb64e9ac")
			
			let mnemonic = try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				return try Mnemonic.encode(entropyBuffer)
			}
			var bytes = [UInt8](repeating: 0, count: 20) // example size
			try bytes.withUnsafeMutableBufferPointer { ptr in
				try Mnemonic.decode(mnemonic, into: ptr.baseAddress!)
			}
			#expect(bytes == entropyBytes)
		}
		@Test func testRoundTrip192bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f")
			
			let mnemonic = try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				return try Mnemonic.encode(entropyBuffer)
			}
			var bytes = [UInt8](repeating: 0, count: 24) // example size
			try bytes.withUnsafeMutableBufferPointer { ptr in
				try Mnemonic.decode(mnemonic, into: ptr.baseAddress!)
			}
			#expect(bytes == entropyBytes)
		}
		@Test func testRoundTrip224bit() throws {
			let entropyBytes: [UInt8] = hexToBytes("a1d3c47b2e98f0d4b76c5a31e9b2d84fa63c97be1f0a2c56d9b4e831")
			
			let mnemonic = try entropyBytes.withUnsafeBufferPointer { entropyBuffer in
				return try Mnemonic.encode(entropyBuffer)
			}
			var bytes = [UInt8](repeating: 0, count: 28) // example size
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
