extension Array where Element == UInt8 {
	public init<E>(RAW_encodable encodableVar:E) where E:RAW_encodable {
		let encSize = encodableVar.RAW_encoded_size()
		self = Self(unsafeUninitializedCapacity:encSize, initializingWith: { buff, size in
			let startPtr = UnsafeMutableRawPointer(buff.baseAddress!)
			let stridePtr = encodableVar.RAW_encode(dest:buff.baseAddress!)
			#if DEBUG
			assert(startPtr.distance(to:stridePtr) == encSize)
			#endif
			size = encSize
		})
	}
	
	public init<E>(RAW_encodables encodableVars:E...) where E:RAW_encodable {
		var buildEncodables = [E]()
		buildEncodables.reserveCapacity(encodableVars.count)
		for encodableVar in encodableVars {
			buildEncodables.append(encodableVar)
		}
		self.init(RAW_encodables:buildEncodables)
	}

	public init<E>(RAW_encodables encodableVars:[E]) where E:RAW_encodable {
		#if DEBUG
		var encSize:size_t = 0
		var varAndExpectedSize = [(E, size_t)]()
		for encodableVar in encodableVars {
			let encodableVarSize = encodableVar.RAW_encoded_size()
			encSize += encodableVarSize
			varAndExpectedSize.append((encodableVar, encodableVarSize))
		}
		#else
		let encSize = encodableVars.reduce(0) { $0 + $1.RAW_encoded_size() }
		#endif

		self = Self(unsafeUninitializedCapacity: encSize, initializingWith: { buff, size in
			var currentPtr = UnsafeMutableRawPointer(buff.baseAddress!)
			#if DEBUG
			for (encodableVar, expectedSize) in varAndExpectedSize {
				let stridePtr = encodableVar.RAW_encode(dest: currentPtr)
				assert(currentPtr.distance(to: stridePtr) == expectedSize)
				currentPtr = stridePtr
			}
			#else
			for encodableVar in encodableVars {
				currentPtr = encodableVar.RAW_encode(dest: currentPtr)
				currentPtr = stridePtr
			}
			#endif
			size = encSize
		})
	}
}