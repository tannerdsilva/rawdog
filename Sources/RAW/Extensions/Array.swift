import struct CRAW.size_t;
import func CRAW.memcpy;

// extension Array:RAW_decodable where Element:RAW_decodable {
//     public static func RAW_decode(ptr:UnsafeRawPointer, size:size_t, stride strideOut:inout size_t) -> Array<Element>? {
// 		// this is the stride that this function moves internally.
// 		var localStride = 0
		
// 		// load the initial count
// 		let expectedElementCount = UInt64.RAW_decode(ptr:ptr, size:size, stride:&localStride)
// 		guard expectedElementCount != nil else {
// 			return nil
// 		}

// 		// load the blank byte that comes after the count
// 		let expectedBlankByte = UInt8.RAW_decode(ptr:ptr.advanced(by:localStride), size:size - localStride, stride:&localStride)
// 		guard expectedBlankByte != nil, expectedBlankByte == 0 else {
// 			return nil
// 		}

// 		// load the elements in the array.
// 		var buildArray = [Element]()
// 		var i:size_t = 0
// 		while i < expectedElementCount! && localStride < size && size - localStride >= (UInt64.RAW_staticbuff_size() + 1) {
// 			// load the size of the element.
// 			let loadedElementSize = UInt64.RAW_decode(ptr:ptr.advanced(by:localStride), size:size - localStride, stride:&localStride)
// 			guard loadedElementSize != nil, loadedElementSize! <= (size - localStride) else {
// 				return nil
// 			}

// 			// build a new val that is truncated to the size of the upcoming element
// 			let elementStartLocation = UnsafeRawPointer(ptr.advanced(by:localStride))
// 			var mutateValue = elementStartLocation

// 			// load the element
// 			let myElement:Element? = Element.RAW_decode(ptr:&mutateValue, size:size - localStride, stride:&localStride)
// 			guard myElement != nil else {
// 				return nil
// 			}

// 			// look for the terminating byte
// 			let elementTerminator = UInt8.RAW_decode(ptr:ptr.advanced(by:localStride), size:size - localStride, stride:&localStride)
// 			guard elementTerminator != nil, elementTerminator == 0 else {
// 				return nil
// 			}
// 			buildArray.append(myElement!)
// 			i += 1
// 		}

// 		// validate that we read the correct number of elements
// 		guard i == expectedElementCount! else {
// 			return nil
// 		}

// 		// load the terminating byte
// 		let myTerminator = UInt8.RAW_decode(ptr:ptr.advanced(by:localStride), size:size - localStride, stride:&localStride)
// 		guard myTerminator != nil, myTerminator == 0 else {
// 			return nil
// 		}

// 		strideOut += localStride

// 		return buildArray
//     }
// }

extension Array where Element == UInt8 {
	public func RAW_encoded_size() -> size_t {
		return self.count
	}

	public func RAW_encode(ptr:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return memcpy(ptr, self, self.count).advanced(by:self.count)
	}

    public static func RAW_decode(ptr:UnsafeRawPointer, size:size_t, stride strideExport:inout size_t) -> Array<Element>? {
		strideExport += size
		return [UInt8](unsafeUninitializedCapacity:size, initializingWith: { bufferPtr, initializedCount in
			memcpy(bufferPtr.baseAddress!, ptr, size)
			initializedCount = size
		})
	}
}

// extension Array:RAW_encodable where Element:RAW_encodable {
//     public func RAW_encoded_size() -> size_t {
// 		// counts the 64 bit count and the 8 bit terminator that comes after it.
//         var buildSize:size_t = UInt64.RAW_staticbuff_size()
// 		buildSize += 1

// 		// for each element, count the size encoding, the element encoding, and the 8 bit terminator that comes after it.
// 		for element in self {
// 			buildSize += UInt64.RAW_staticbuff_size()
// 			buildSize += element.RAW_encoded_size()
// 			buildSize += 1
// 		}

// 		// count the final 8 bit terminator.
// 		buildSize += 1
// 		return buildSize
//     }

//     public func RAW_encode(ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
// 		let nullCharacter:UInt8 = 0
// 		let selfCount = UInt64(self.count)
//         var curPtr = ptr
// 		// write the count
// 		curPtr = selfCount.RAW_encode(ptr:curPtr)
// 		// write the null character
// 		curPtr = nullCharacter.RAW_encode(ptr:curPtr)

// 		for element in self {
// 			let encodingSize = UInt64(element.RAW_encoded_size())

			
// 			curPtr = element.RAW_encode(ptr:curPtr)
// 		}
// 		return curPtr
//     }
// }