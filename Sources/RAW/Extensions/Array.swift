import struct CRAW.size_t;

extension Array where Element == UInt8 {
	public func asRAW_val<R>(_ valFunc:(RAW) throws -> R) rethrows -> R {
		if let hasContiguousBytes = try self.withContiguousStorageIfAvailable({ (bytes) -> R in
			return try valFunc(RAW(bytes.baseAddress!, UInt64(bytes.count)))
		}) {
			return hasContiguousBytes
		} else {
			let newBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:self.count)
			defer {
				newBuffer.deallocate()
			}
			for (index, element) in self.enumerated() {
				newBuffer[index] = element
			}
			return try valFunc(RAW(newBuffer.baseAddress!, UInt64(self.count)))
		}
	}
}

extension Array:RAW_decodable where Element:RAW_decodable {
	public init?(RAW_size:size_t, RAW_data:UnsafeRawPointer?) {
		guard (RAW_data != nil) else {
			return nil
		}
		if RAW_size > 0 {
			var existingVal = RAW(RAW_size, RAW_data)
			var buildElements = [Element]()
			while let (element, newVal) = existingVal.consume(Element.self) {
				existingVal = newVal
				buildElements.append(element)
			}
			self = buildElements
		} else {
			self = []
		}
	}
}

extension Array where Element == any RAW_encodable {
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