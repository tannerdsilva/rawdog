// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import RAW
import RAW_blake2

public func checksumBitCount(bytes length: size_t) -> size_t {
	let checksumLength = (length * 8) / 32
	return checksumLength
}

public func wordCountWithChecksum(bytes length: size_t) -> size_t {
	let checksumLength = checksumBitCount(bytes:length)
	let wordCount = ((length * 8) + checksumLength) / 11
	return wordCount
}


public func encode(_ data:UnsafeBufferPointer<UInt8>, into words:UnsafeMutableBufferPointer<Word>) throws {
	let dataBits = data.count * 8
	let checksumBits = dataBits / 32
	var hasher = try RAW_blake2.Hasher<B, [UInt8]>(outputLength:32)
	try hasher.update(UnsafeRawBufferPointer(data))
	let checksum = Array(try hasher.finish().dropFirst(checksumBitCount(bytes:data.count)))
	let newBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:(dataBits + checksumBits + 7) / 8)
	defer {
		newBuffer.deallocate()
	}
	_ = RAW_memcpy(newBuffer.baseAddress!, data.baseAddress!, data.count)
	_ = RAW_memcpy(newBuffer.baseAddress! + data.count, checksum, checksum.count)

	// encode the data into words
	let totalBits = dataBits + checksumBits
	var bitIndex = 0
	var wi = 0;
	while bitIndex < totalBits {
		if (bitIndex + 11 <= totalBits) {
			// extract 11 bits as a number
			let byteIndex = bitIndex / 8
			let bitOffset = bitIndex % 8
			var index:UInt16 = (UInt16(newBuffer[byteIndex]) << 8) | UInt16(newBuffer[byteIndex + 1])
			index = (index >> (7 - bitOffset)) & 0x7FF
			words[wi] = Word(rawValue:index)!
			bitIndex += 11
			wi += 1
		} else {
			break;
		}
	}
	fatalError("not complete")
}

public func decode(_ words:UnsafeBufferPointer<Word>, into data:UnsafeMutablePointer<UInt8>) {
	var bitIndex = 0
	for i in 0..<words.count {
		let word = words[i]
		let byteIndex = bitIndex / 8
		let offset = bitIndex % 8
		let index = word.rawValue
		data[byteIndex] |= UInt8(index >> (3 + offset))
		if (offset > 3) {
			data[byteIndex + 1] |= UInt8(index << (13 - offset))
		}
		bitIndex += 11
	}
	let dataBits = bitIndex - ((words.count * 11) - 256)

	// recalculate the checksum
	var hasher = try! RAW_blake2.Hasher<B, [UInt8]>(outputLength:32)
	try! hasher.update(UnsafeRawBufferPointer(start:data, count:(dataBits + 7) / 8))
	// let checksum = Array(try! hasher.finish().dropFirst(checksumBitCount(bytes:(dataBits + 7) / 8)))
	fatalError("not complete")
}
