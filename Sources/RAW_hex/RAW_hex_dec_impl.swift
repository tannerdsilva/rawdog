import RAW

internal struct Decode {
	/// computes the number of decoded bytes that would be required to decode the given number of encoded bytes.
	/// - throws: ``Error.invalidEncodingSize`` if the number of encoded bytes is not a valid size for the decoding algorithm.
	internal static func length(_ bytes:size_t) throws -> size_t {
		switch bytes % 2 {
			case 0:
				return bytes / 2
			default:
				throw Error.invalidEncodingSize(bytes)
		}
	}

	/// primary decoding function for the  decoder.
	// internal static func process(bytes values:UnsafePointer<UInt8>, count value_size:size_t) throws -> ([UInt8], size_t) {
	// 	// compute the length of the input buffer. if it's less than 2, we can't decode it.
	// 	let inputLength:size_t = value_size
		
	// 	#if RAWDOG_HEX_LOG
	// 	logger.info("initiating decode of \(inputLength) encoded bytes.", metadata:["output_length": "\(inputLength / 2)"])
	// 	#endif

	// 	let outputTheoreticalLength:size_t = Encode.length(inputLength)

	// 	#if RAWDOG_HEX_LOG
	// 	logger.debug("theoretical output length is \(outputTheoreticalLength) bytes.", metadata:["output_length": "\(outputTheoreticalLength)"])
	// 	#endif

	// 	var outputStride = 0
	// 	let outputBytes = try [UInt8](unsafeUninitializedCapacity:outputTheoreticalLength, initializingWith: { outputBuffer, outStrided in
	// 		outStrided = 0
	// 		var inputScan:size_t = 0
	// 		while ((inputLength - inputScan) > 1) {
	// 			#if RAWDOG_HEX_LOG
	// 			logger.debug("decoding byte at index \(inputScan).", metadata:["input_index": "\(inputScan)"])
	// 			#endif
				
	// 			defer {
	// 				outStrided += 1
	// 				inputScan += 2
	// 			}

	// 			// read two bytes
	// 			#if RAWDOG_HEX_LOG
	// 			logger.trace("got v1 value \(values[inputScan]) | \(values[inputScan].asciiValue()).", metadata:["input_index": "\(inputScan)"])
	// 			logger.trace("got v2 value \(values[inputScan + 1]) | \(values[inputScan].asciiValue()).", metadata:["input_index": "\(inputScan + 1)"])
	// 			#endif

	// 			let v1 = try Value(validate:values[inputScan]).hexcharIndexValue()
	// 			let v2 = try Value(validate:values[inputScan + 1]).hexcharIndexValue()

	// 			#if RAWDOG_HEX_LOG
	// 			logger.trace("v1 value is \(v1).", metadata:["input_index": "\(inputScan)", "v1": "\(v1)"])
	// 			logger.trace("v2 value is \(v2).", metadata:["input_index": "\(inputScan + 1)", "v2": "\(v2)"])
	// 			#endif

	// 			// write one byte
	// 			outputBuffer[outStrided] = (v1 << 4) | v2
	// 		}
	// 		#if DEBUG
	// 		assert((inputLength - inputScan) == 0, "input length should be zero at this point. if it's not, we have a bug. \((inputLength - inputScan))")
	// 		#endif
	// 		outputStride = outStrided
	// 	})
	// 	#if RAWDOG_HEX_LOG
	// 	for (index, byte) in outputBytes.enumerated() {
	// 		logger.trace("decoded byte at index \(index) is \(byte).", metadata:["output_index": "\(index)", "byte": "\(byte)"])
	// 	}
	// 	#endif
	// 	return (outputBytes, outputStride)
	// }
	// internal static func process(values:)

	// value handler for the decoding process.
	// internal static func process(values:UnsafePointer<Value>, count value_size:size_t) throws -> ([UInt8], size_t) {
	// 	// compute the length of the input buffer. if it's less than 2, we can't decode it.
	// 	let inputLength:size_t = value_size
		
	// 	#if RAWDOG_HEX_LOG
	// 	logger.info("initiating decode of \(inputLength) encoded bytes.", metadata:["output_length": "\(inputLength / 2)"])
	// 	#endif

	// 	let outputTheoreticalLength:size_t = Encode.length(inputLength)

	// 	#if RAWDOG_HEX_LOG
	// 	logger.debug("theoretical output length is \(outputTheoreticalLength) bytes.", metadata:["output_length": "\(outputTheoreticalLength)"])
	// 	#endif
	// 	var outputStride = 0
	// 	let outputBytes = [UInt8](unsafeUninitializedCapacity:outputTheoreticalLength, initializingWith: { outputBuffer, outStrided in
	// 		outStrided = 0
	// 		var inputScan:size_t = 0
	// 		while ((inputLength - inputScan) > 1) {
	// 			#if RAWDOG_HEX_LOG
	// 			logger.debug("decoding byte at index \(inputScan).", metadata:["input_index": "\(inputScan)"])
	// 			#endif
				
	// 			defer {
	// 				outStrided += 1
	// 				inputScan += 2
	// 			}

	// 			// read two bytes
	// 			#if RAWDOG_HEX_LOG
	// 			logger.trace("got v1 value \(values[inputScan]) | \(values[inputScan].asciiValue()).", metadata:["input_index": "\(inputScan)"])
	// 			logger.trace("got v2 value \(values[inputScan + 1]) | \(values[inputScan].asciiValue()).", metadata:["input_index": "\(inputScan + 1)"])
	// 			#endif

	// 			let v1 = values[inputScan].hexcharIndexValue()
	// 			let v2 = values[inputScan + 1].hexcharIndexValue()

	// 			#if RAWDOG_HEX_LOG
	// 			logger.trace("v1 value is \(v1).", metadata:["input_index": "\(inputScan)", "v1": "\(v1)"])
	// 			logger.trace("v2 value is \(v2).", metadata:["input_index": "\(inputScan + 1)", "v2": "\(v2)"])
	// 			#endif

	// 			// write one byte
	// 			outputBuffer[outStrided] = (v1 << 4) | v2
	// 		}
	// 		#if DEBUG
	// 		assert((inputLength - inputScan) == 0, "input length should be zero at this point. if it's not, we have a bug. \((inputLength - inputScan))")
	// 		#endif
	// 		outputStride = outStrided
	// 	})
	// 	#if RAWDOG_HEX_LOG
	// 	for (index, byte) in outputBytes.enumerated() {
	// 		logger.trace("decoded byte at index \(index) is \(byte).", metadata:["output_index": "\(index)", "byte": "\(byte)"])
	// 	}
	// 	#endif
	// 	return (outputBytes, outputStride)
	// }
}

// get decoded bytes from encoded values
internal struct _decode_main_values:Sequence {
	internal consuming func makeIterator() -> _Iterator<[Value].Iterator> {
		return _Iterator(decoded_values.makeIterator())
	}

	internal struct _Iterator<I>:IteratorProtocol where I:IteratorProtocol, I.Element == Value  {
		private var valIterate:[Value].Iterator
		internal init(_ decoded_values:consuming [Value].Iterator) {
			self.valIterate = decoded_values
		}
		internal mutating func next() -> UInt8? {
			guard let v1 = valIterate.next() else {
				return nil
			}
			return (v1.hexcharIndexValue() << 4) |  valIterate.next()!.hexcharIndexValue()
		}
	}
	private let decoded_values:[Value]
	internal init(_ input:consuming [Value]) {
		self.decoded_values = input
	}
}
