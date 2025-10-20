// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import RAW
import RAW_sha256

public struct Mnemonic {
	enum Error:Swift.Error {
		case unsupportedDataByteCount(Int)
		case unsupportedWordCount(Int)
		case unknownWord(String)
		case checksumMismatch
		
		var errorDescription: String? {
			switch self {
				case .unsupportedDataByteCount(let length):
					return "Invalid entropy length (\(length) bytes). Must be 16–32 bytes and multiple of 4."
				case .unsupportedWordCount(let length):
					return "Invalid word count (\(length)). Must be 12-24 words and a multiple of 3."
				case .unknownWord(let word):
					return "Decoded unknown mnemonic word: \(word)"
				default:
					return nil
			}
		}
	}
	
	static public func checksumBitCount(bytes length: size_t) -> size_t {
		let checksumLength = (length * 8) / 32
		return checksumLength
	}
	
	static public func wordCountWithChecksum(bytes length: size_t) -> size_t {
		let checksumLength = checksumBitCount(bytes:length)
		let wordCount = ((length * 8) + checksumLength) / 11
		return wordCount
	}
	
	
	static public func encode(_ data:UnsafeBufferPointer<UInt8>) throws -> [String] {
		guard data.count >= 16 && data.count <= 32 && data.count.isMultiple(of:4) else {
			throw Error.unsupportedDataByteCount(data.count)
		}
	
		var hashBytes = [UInt8](repeating: 0, count: 32)
		var hasher = Hasher<Hash>()
		hasher.update(data)
		try hasher.finish(into: &hashBytes)

		let checksumBits:Int = checksumBitCount(bytes: data.count)
		
		var words: [String] = []
		
		var acc: UInt16 = 0      // will hold at most 16 bits
		var accBits = 0          // number of bits currently in `acc`

		@inline(__always) func push(bit: UInt8) {
			acc = (acc << 1) | UInt16(bit)
			accBits += 1

			// Whenever we have 11 or more bits we can emit a word
			if accBits >= 11 {
				let shift = accBits - 11
				let idx = Int((acc >> shift) & 0x7FF)
				words.append(WordList.english[idx])

				acc &= (1 << shift) - 1
				accBits = shift
			}
		}

		for byte in data {
			for i in (0..<8).reversed() {
				let bit = (byte >> i) & 0x01
				push(bit: bit)
			}
		}
		
		for i in 0..<checksumBits {
			let byteIndex = i / 8
			let bitIndex  = 7 - (i % 8)
			let bit = (hashBytes[byteIndex] >> bitIndex) & 0x01
			push(bit: bit)
		}
		
		// Encode last word if there are leftover bits
		if accBits > 0 {
			let shift = 11 - accBits
			let idx = Int((acc << shift) & 0x7FF)
			words.append(WordList.english[idx])
		}
		
		return words
	}
	
	static public func decode(_ words:[String], into data:UnsafeMutablePointer<UInt8>) throws {
		guard words.count >= 12 && words.count <= 24 && words.count.isMultiple(of:3) else {
			throw Error.unsupportedWordCount(words.count)
		}
		
		var indices: [UInt16] = []

		for w in words {
			guard let idx = WordList.englishIndex[w] else {
				throw Error.unknownWord(w)
			}
			indices.append(UInt16(idx))
		}
		
		var acc: UInt16 = 0
		var accBits = 0
		
		let entropyBits = words.count * 11 * 32 / 33
		let checksumBits  = words.count * 11 - entropyBits
		let entropyBytes = entropyBits / 8
		
		var entropy = [UInt8](repeating: 0, count: entropyBytes)
		var byteIdx = 0

		for idx in indices {
			for i in (0..<11).reversed() {
				let bit = UInt16((idx >> i) & 1)
				acc = (acc << 1) | UInt16(bit)
				accBits += 1

				if accBits == 8  && byteIdx < entropyBytes {
					entropy[byteIdx] = UInt8(acc)
					acc = 0
					accBits = 0
					byteIdx += 1
				}
			}
		}

		// ---------- Verify checksum ----------
		var hasher = Hasher<Hash>()
		try hasher.update(entropy)
		var hash = [UInt8](repeating: 0, count: 32)
		try hasher.finish(into: &hash)

		// Pull out the first `checksumBits` bits of the digest.
		var trueCS: UInt16 = 0
		var csBits = 0
		for i in 0..<checksumBits {
			let byteIndex = i / 8
			let bitIndex  = 7 - (i % 8)
			let bit = (hash[byteIndex] >> bitIndex) & 0x01
			trueCS = (trueCS << 1) | UInt16(bit)
			csBits += 1
		}

		let mnemonicCS = UInt16(acc & ((1 << checksumBits) - 1))

		if mnemonicCS != trueCS {
			throw Error.checksumMismatch
		}

		// ---------- CheckSum Verified, Copy Data ----------
		for i in 0..<entropyBytes {
			data[i] = entropy[i]
		}
	}
}
