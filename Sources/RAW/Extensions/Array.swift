import struct CRAW.size_t;
import func CRAW.memcpy;

extension Array where Element == UInt8 {
	/// converts the byte values of an array into a RAW_val that low level functions can operate within.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		var bytesLength:size_t = self.count
		if let hasContiguousBytes = try self.withContiguousStorageIfAvailable({ (bytes) -> R in
			return try valFunc(bytes.baseAddress!, &bytesLength)
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
			return try valFunc(newBuffer.baseAddress!, &bytesLength)
		}
	}
}

extension Array:RAW_decodable where Element:RAW_decodable {
	/// initialize the array with repeated contents of a RAW_decodable Element type
	public init(RAW_data:UnsafeRawPointer, RAW_size:UnsafePointer<size_t>) {
		guard RAW_size.pointee > 0 else {
			self = []
			return
		}
		var existingVal = val(RAW_data:RAW_data, RAW_size:RAW_size)
		var buildElements = [Element]()
		while let newVal = existingVal.consume(Element.self) {
			buildElements.append(newVal)
		}
		self = buildElements
	}
}

extension Array where Element == UInt8 {
	public init(RAW_size:size_t, RAW_data:UnsafeRawPointer) {
		guard RAW_size > 0 else {
			self = []
			return
		}
		self = [UInt8](unsafeUninitializedCapacity:RAW_size, initializingWith: { ptr, buffSize in
			memcpy(ptr.baseAddress!, RAW_data, RAW_size)
			buffSize = RAW_size
		})
	}
}

extension Array:RAW_encodable where Element:RAW_encodable {
	/// default implementation of RAW_val that exports each RAW_encodable Element into a contiguous byte stream.
	public func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
		var buildBytes = [UInt8]()
		for element in self {
			let elementBytes = element.asRAW_val { rawData, rawSize in
				return Array<UInt8>(RAW_data:rawData, RAW_size:rawSize)
			}
			buildBytes.append(contentsOf:elementBytes)
		}
		return try buildBytes.asRAW_val(valFunc)
	}
}