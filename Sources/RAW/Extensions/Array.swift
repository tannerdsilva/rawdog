extension Array where Element == UInt8 {
    public func RAW_encoded_size() -> size_t {
        return self.count
    }

	public init<E>(RAW_encodable encodableVar:E) where E:RAW_encodable {
		let encSize = encodableVar.RAW_encoded_size()
		self = Self(unsafeUninitializedCapacity:encSize, initializingWith: { buff, size in
			let startPtr = UnsafeMutableRawPointer(buff.baseAddress!)
			let stridePtr = encodableVar.RAW_encode(dest:startPtr)
			#if DEBUG
			assert(abs(startPtr.distance(to:stridePtr)) == encSize, "encodableVar.RAW_encode(dest:) did not return a pointer that is the correct distance from the start pointer. expected: \(encSize), actual: \(abs(startPtr.distance(to:stridePtr))). type was: \(type(of:encodableVar))")
			#endif
			size = encSize
		})
	}
	
	public init<E>(RAW_encodables encodableVars:E...) where E:RAW_encodable {
		self.init(RAW_encodables:[E](unsafeUninitializedCapacity:encodableVars.count, initializingWith: { eBuff, eCount in
			eCount = 0
			var writeSeek = eBuff.baseAddress!
			for encodableVar in encodableVars {
				writeSeek.initialize(to: encodableVar)
				writeSeek += 1
				eCount += 1
			}
		}))
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
			}
			#endif
			size = encSize
		})
	}
}