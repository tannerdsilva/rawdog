import RAW
import CRAW

public struct Base64 {
	/// error thrown by Base64 encoding/decoding functions
	public enum Error:Swift.Error {
		/// the provided string could not be decoded
		case decodingError(String, Int32)

		/// the provided string could not be encoded
		case encodingError([UInt8], Int32)
	}

	/// encode a byte array to a base64 string
	/// - parameter bytes: the byte array to encode
	public static func encode<RE>(bytes rawBytes:RE) -> String where RE:RAW_encodable {
		return rawBytes.asRAW_val { rawVal in
			let enclen = base64_encoded_length(rawVal.RAW_size) + 1
			let newBytes = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:enclen)
			defer {
				newBytes.deallocate()
			}
			let encodeResult = base64_encode(newBytes.baseAddress, enclen, rawVal.RAW_data, rawVal.RAW_size)
			guard encodeResult >= 0 else {
				fatalError("could not encode base64 string")
			}
			return String(cString:newBytes.baseAddress!)
		}
	}
	
	/// decode a base64 string to a byte array
	/// - parameter dataEncoding: the base64 string to decode
	public static func decode(_ dataEncoding:String) -> [UInt8] {
		let newBytes = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:base64_decoded_length(dataEncoding.count))
		defer {
			newBytes.deallocate()
		}
		let decodeResult = base64_decode(newBytes.baseAddress, base64_decoded_length(dataEncoding.count), dataEncoding, dataEncoding.count)
		guard decodeResult >= 0 else {
			fatalError("could not decode base64 string")
		}
		return Array(unsafeUninitializedCapacity:decodeResult, initializingWith: { (buffer, count) in
			memcpy(buffer.baseAddress!, newBytes.baseAddress, decodeResult)
			count = decodeResult
		})
	}
}