import RAW_hmac
import RAW

extension RAW_hasher {
    public static func hkdfExtract(salt:[UInt8]?, ikm:[UInt8]) throws -> [UInt8] {
        return try Self.hmac(key:salt ?? [UInt8](repeating: 0, count: Self.RAW_hasher_outputsize), message: ikm)
    }

    public static func hkdfExpand(prk: [UInt8], info: [UInt8]?, len: Int) throws -> [UInt8] {
        var output = [UInt8]()
        var t = [UInt8]()
        var blockCounter: UInt8 = 1

        while output.count < len {
            var message = t
            if let info = info {
                message.append(contentsOf: info)
            }
            message.append(blockCounter)
            t = try Self.hmac(key: prk, message: Array(message))
            let needed = min(t.count, len - output.count)
            output.append(contentsOf: t.prefix(needed))
            blockCounter += 1
        }

        return Array(output.prefix(len))
    }
}