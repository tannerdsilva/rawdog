import RAW_hmac
import RAW

extension RAW_hasher {
    public static func hkdfExtract(salt: [UInt8]?, ikm: [UInt8]) throws -> [UInt8] {
        // Use the correctly formatted salt to perform HMAC
        return try Self.hmac(key:salt ?? [UInt8](repeating: 0, count: Self.RAW_hasher_outputsize), message: ikm)
    }

    public static func hkdfExpand(prk:[UInt8], info:[UInt8]?, len: Int) throws -> [UInt8] {
        var output = [UInt8]()
        var t = [UInt8]()
        var blockCounter:UInt8 = 1

        while output.count < len {
            var message = t
			if let hasInfo = info {
            	message.append(contentsOf:hasInfo)
			}
            message.append(blockCounter)
            t = try Self.hmac(key: prk, message: Array(message))
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