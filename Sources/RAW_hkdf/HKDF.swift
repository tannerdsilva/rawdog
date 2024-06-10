import RAW_hmac
import RAW

extension RAW_hasher {
	public static func hkdfExtract(salt:[UInt8]?, ikm:[UInt8]) throws -> [UInt8] {
		let realSalt = salt ?? [UInt8](repeating: 0, count: Self.RAW_hasher_blocksize)
		return try Self.hmac(key: realSalt, message: ikm)
	}
	public static func hkdfExpand(prk: [UInt8], info: [UInt8]?, len: Int) throws -> [UInt8] {
		var output = [UInt8]()
		var t = [UInt8]()
		var blockCounter: UInt8 = 1
		var remainingLength = len
	
		while output.count < len {
			var message = t
			if let info = info {
				message.append(contentsOf: info)
			}
			message.append(blockCounter)
			t = try Self.hmac(key: prk, message: message)
			let needed = min(t.count, remainingLength)
			output.append(contentsOf: t[0..<needed])
			blockCounter += 1
			remainingLength -= needed
		}
	
		return Array(output.prefix(len))
	}
	public static func hkdf(key: [UInt8], salt: [UInt8]?, info: [UInt8]?, outputLength: Int) throws -> [UInt8] {
		let prk = try Self.hkdfExtract(salt: salt, ikm: key)
		let okm = try Self.hkdfExpand(prk: prk, info: info, len: outputLength)
		return okm
	}
}