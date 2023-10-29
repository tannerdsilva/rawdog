extension Array:RAW_encodable where Element:RAW_encodable {
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		var buildBytes = [UInt8]()
		for element in self {
			let elementBytes = element.asRAW_val { rawVal in
				return Array<UInt8>(rawVal)
			}
			buildBytes.append(contentsOf:elementBytes)
		}
		return try buildBytes.asRAW_val(valFunc)
	}
}

extension Array:RAW_decodable where Element:RAW_decodable {
	public init(RAW_size:UInt64, RAW_data:UnsafeRawPointer?) {
		self.init()
		guard (RAW_size > 0) else {
			return
		}
		guard (RAW_data != nil) else {
			return
		}
		var existingVal = RAW(RAW_size, RAW_data)
		var buildElements = [Element]()
		while let (element, newVal) = existingVal.consume(Element.self) {
			existingVal = newVal
			buildElements.append(element)
		}
		self = buildElements
	}
}