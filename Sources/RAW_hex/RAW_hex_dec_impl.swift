import RAW

internal struct Decode {
	/// primary decoding function for the  decoder.
	internal static func process(values:UnsafePointer<Value>, value_size:size_t) throws -> [UInt8] {
		// compute the length of the input buffer. if it's less than 2, we can't decode it.
		let inputLength:size_t = value_size
		guard [Value].isEncodingSizeValid(inputLength) else {
			throw Error.invalidEncodingSize(inputLength)
		}
		
		#if RAWDOG_HEX_LOG
		logger.info("initiating decode of \(inputLength) encoded bytes.", metadata:["output_length": "\(inputLength / 2)"])
		#endif

		let outputTheoreticalLength:size_t = [Value].decodedSize(forEncodedByteCount:inputLength)

		#if RAWDOG_HEX_LOG
		logger.debug("theoretical output length is \(outputTheoreticalLength) bytes.", metadata:["output_length": "\(outputTheoreticalLength)"])
		#endif

		let outputBytes = [UInt8](unsafeUninitializedCapacity:outputTheoreticalLength, initializingWith: { outputBuffer, outStrided in
			outStrided = 0
			var inputScan:size_t = 0
			while ((inputLength - inputScan) > 1) {
				#if RAWDOG_HEX_LOG
				logger.debug("decoding byte at index \(inputScan).", metadata:["input_index": "\(inputScan)"])
				#endif
				
				defer {
					outStrided += 1
					inputScan += 2
				}

				// read two bytes
				#if RAWDOG_HEX_LOG
				logger.debug("got v1 value \(values[inputScan]) | \(values[inputScan].asciiValue()).", metadata:["input_index": "\(inputScan)"])
				logger.debug("got v2 value \(values[inputScan + 1]) | \(values[inputScan].asciiValue()).", metadata:["input_index": "\(inputScan + 1)"])
				#endif

				let v1 = values[inputScan].hexcharIndexValue()
				let v2 = values[inputScan + 1].hexcharIndexValue()

				#if RAWDOG_HEX_LOG
				logger.debug("v1 value is \(v1).", metadata:["input_index": "\(inputScan)", "v1": "\(v1)"])
				logger.debug("v2 value is \(v2).", metadata:["input_index": "\(inputScan + 1)", "v2": "\(v2)"])
				#endif

				// write one byte
				outputBuffer[outStrided] = (v1 << 4) | v2
			}
			#if DEBUG
			assert((inputLength - inputScan) == 0, "input length should be zero at this point. if it's not, we have a bug. \((inputLength - inputScan))")
			#endif
		})
		#if RAWDOG_HEX_LOG
		for (index, byte) in outputBytes.enumerated() {
			logger.notice("decoded byte at index \(index) is \(byte).", metadata:["output_index": "\(index)", "byte": "\(byte)"])
		}
		#endif
		return outputBytes
	}
}