

extension Array:RAW_encodable where Element:RAW_encodable {
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		var buildBytes = [UInt8]()
		for element in self {
			let elementBytes = element.asRAW_val { rawVal in
				var buildBytes = [UInt8]()
				for byte in rawVal {
					buildBytes.append(byte)
				}
				return buildBytes
			}
			buildBytes.append(contentsOf:elementBytes)
		}
		return try buildBytes.asRAW_val(valFunc)
	}
}