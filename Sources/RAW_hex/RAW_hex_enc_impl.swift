import RAW
internal struct Encode {

	/// computes the number of encoded bytes that would be required to encode the given number of unencoded bytes.
	internal static func length(_ bytes:size_t) -> size_t {
		return bytes * 2
	}

	internal static func process_inline(decoded_data:UnsafePointer<UInt8>, encoded_index:size_t) -> (Value, Value) {
		let byte = decoded_data[encoded_index / 2]
		let high = byte >> 4
		let low = byte & 0x0F
		return (Value(hexcharIndexValue:high), Value(hexcharIndexValue:low))
	}
}

/// get values from raw decoded byte intake
internal struct _encoder_main:Sequence {
	internal struct _Iterator<S>:IteratorProtocol where S:Sequence, S.Element == UInt8 {
		private var byteIterate:S.Iterator
		private var needsNextByte:Bool = true
		private var curByte:UInt8 = 0
		internal init(_ decoded_bytes:consuming S) {
			self.byteIterate = decoded_bytes.makeIterator()
		}
		internal mutating func next() -> Value? {
			if needsNextByte == true {
				guard let nextByte = byteIterate.next() else {
					return nil
				}
				curByte = nextByte
				needsNextByte = false
				return Value(hexcharIndexValue:curByte >> 4)
			} else {
				needsNextByte = true
				return Value(hexcharIndexValue:curByte & 0x0F)
			}
		}

	}

	internal consuming func makeIterator() -> _Iterator<[UInt8]> {
		return _Iterator(_storedBytes)
	}
	
	private let _storedBytes:[UInt8]
	internal init(_ encoded:consuming Encoded) {
		self._storedBytes = encoded.decoded_data
	}
	internal init(decoded decoded_values:consuming [UInt8]) {
		self._storedBytes = decoded_values
	}
}

/// get characters from raw decoded byte intake
internal struct _encoder_main_char:Sequence {
	internal struct _Iterator<S>:IteratorProtocol where S:Sequence, S.Element == Value {
		fileprivate var encoder:S.Iterator
		internal init(_ bytes:consuming S) {
			self.encoder = bytes.makeIterator()
		}
		internal mutating func next() -> Character? {
			guard let curValue = encoder.next() else {
				return nil
			}
			return Character(UnicodeScalar(curValue.asciiValue()))
		}
	}

	internal consuming func makeIterator() -> _Iterator<_encoder_main> {
		return _Iterator(decodedBytes)
	}
	fileprivate let decodedBytes:_encoder_main
	internal init(_ encoded:consuming Encoded) {
		self.decodedBytes = _encoder_main(encoded)
	}
}