extension String:RAW_convertible {
    public init?(RAW_decode:UnsafeRawPointer, count: size_t) {
		let asBuffer = UnsafeBufferPointer(start:RAW_decode.assumingMemoryBound(to:UInt8.self), count:count)
		self.init(decoding:asBuffer, as:UTF8.self)
	}

	public func RAW_encoded_size() -> size_t {
		return self.utf8.count
	}
	
	public func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		var seeker = dest.assumingMemoryBound(to:UInt8.self)
		for byte in self.utf8 {
			seeker.initialize(to:byte)
			seeker += 1
		}
		return UnsafeMutableRawPointer(seeker)
	}
}