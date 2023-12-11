import RAW
import CRAW
import CRAW_base64

/// a namespace for base64 encoding/decoding functions.
public struct Base64 {
	
	/// error thrown by Base64 encoding/decoding functions
	public enum Error:Swift.Error {
		
		/// the provided string could not be decoded.
		case decodingError(String, Int32)

		/// the provided string could not be encoded.
		case encodingError([UInt8], Int32)
	}

	/// encode a bytestream representatin to a base64 string.
	/// - parameter bytes: the byte representation to encode.
	/// - throws: ``Error.encodingError`` if the byte representation could not be encoded. this should never be thrown under normal operating conditions.
	public static func encode<RE>(bytes rawBytes:RE) throws -> String where RE:RAW_encodable {
		return try rawBytes.asRAW_val { rawDat, rawSiz in
			let enclen = base64_encoded_length(rawSiz.pointee) + 1
			let newBytes = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:enclen)
			defer {
				newBytes.deallocate()
			}
			let encodeResult = base64_encode(newBytes.baseAddress, enclen, rawDat, rawSiz.pointee)
			guard encodeResult >= 0 else {
				throw Error.encodingError(Array(RAW_data:rawDat, RAW_size:rawSiz), geterrno())
			}
			return String(cString:newBytes.baseAddress!)
		}
	}
	
	/// decode a base64 string to a byte array.
	/// - parameter dataEncoding: the base64 string to decode.
	/// - throws: ``Error.decodingError`` if the base64 string could not be decoded. this should never be thrown under normal operating conditions.
	public static func decode(_ dataEncoding:String) throws -> [UInt8] {
		let newBytes = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:base64_decoded_length(dataEncoding.count))
		defer {
			newBytes.deallocate()
		}
		let decodeResult = base64_decode(newBytes.baseAddress, base64_decoded_length(dataEncoding.count), dataEncoding, dataEncoding.count)
		guard decodeResult >= 0 else {
			throw Error.decodingError(dataEncoding, geterrno())
		}
		return Array(unsafeUninitializedCapacity:decodeResult, initializingWith: { (buffer, count) in
			memcpy(buffer.baseAddress!, newBytes.baseAddress!, decodeResult)
			count = decodeResult
		})
	}
}