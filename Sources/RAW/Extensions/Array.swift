// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
extension Array:RAW_accessible, RAW_encodable where Element == UInt8 {
    public mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
		func accessBytes(_ unsafePtr:UnsafeMutablePointer<UInt8>, _ count:Int) throws(E) -> R where E:Swift.Error {
			return try body(.init(start:unsafePtr, count:count))
		}
		return try accessBytes(&self, count)
    }

    public borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error {
		func accessBytes(_ unsafePtr:UnsafePointer<UInt8>) throws(E) -> R where E:Swift.Error {
			return try body(.init(start:unsafePtr, count:count))
		}
		return try withUnsafePointer(to:self) { (ptr:UnsafePointer<Self>) throws(E) -> R in
			return try accessBytes(ptr.pointee)
		}
    }
}

extension Array:RAW_decodable where Element == UInt8 {
	public init?(RAW_decode buff:UnsafeRawBufferPointer) {
		self.init(UnsafeBufferPointer<UInt8>(start:buff.baseAddress!.assumingMemoryBound(to:UInt8.self), count:buff.count))
	}
}

extension Array:RAW_comparable where Element == UInt8 {}