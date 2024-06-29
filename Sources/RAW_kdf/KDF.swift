import RAW_hmac
import RAW

extension RAW_hasher {
    public static func hkdfExtract<IKM>(salt:[UInt8]?, ikm:borrowing IKM) throws -> RAW_hasher_outputtype where IKM:RAW_accessible {
        return try Self.hmac(key:salt ?? [UInt8](repeating: 0, count:MemoryLayout<RAW_hasher_outputtype>.size), message:ikm)
    }

    public static func hkdfExpand<PRK>(prk:PRK, info:[UInt8]?, len:Int) throws -> [UInt8] where PRK:RAW_accessible {
        var output = [UInt8]()
        var t = [UInt8]()
        var blockCounter: UInt8 = 1

        while output.count < len {
            var message = t
            if let info = info {
                message.append(contentsOf: info)
            }
            message.append(blockCounter)
            t = try Self.hmac(key: prk, message: Array(message)).RAW_access {
				return [UInt8](RAW_decode:$0.baseAddress!, count:$0.count)
			}
            let needed = min(t.count, len - output.count)
            output.append(contentsOf: t.prefix(needed))
            blockCounter += 1
        }

        return Array(output.prefix(len))
    }

	public static func hkdf(key:[UInt8], salt:[UInt8]?, info:[UInt8]?, outputLength:Int) throws -> [UInt8] {
		let prk = try Self.hkdfExtract(salt: salt, ikm: key)
		let okm = try Self.hkdfExpand(prk: prk, info:info, len: outputLength)
		return okm
	}
}