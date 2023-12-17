import CRAW_hex
import RAW

enum Error: Swift.Error {
	/// general error that is thrown when a function returns false
	case hexDecodeFailed
	case hexEncodeFailed
}

public func hex_decode(_ hex:String, to:[UInt8].Type) throws -> [UInt8] {
	let hexDataSize = hex_data_size(hex.count)
	let decodedData = try [UInt8](unsafeUninitializedCapacity:hexDataSize, initializingWith: { (buffer, count) in
		count = hexDataSize
		guard hex_decode(hex, hex.count, buffer.baseAddress!, buffer.count) == true else {
			throw Error.hexDecodeFailed
		}
	})
	return decodedData
}

public func hex_decode<O>(_ hex:String, to:O) throws -> O? where O:RAW_decodable {
	let hexDataSize = hex_data_size(hex.count)
	let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity:hexDataSize)
	defer {
		buffer.deallocate()
	}
	guard hex_decode(hex, hex.count, buffer.baseAddress, hexDataSize) == true else {
		throw Error.hexDecodeFailed
	}
	return withUnsafePointer(to:hexDataSize) { (sizePtr) -> O? in
		return O(RAW_data:buffer.baseAddress!, RAW_size:sizePtr)
	}
}

public func hex_encode<I>(_ encodable_input:I) throws -> String where I:RAW_encodable {
	return try encodable_input.asRAW_val { (dataPtr, dataPtrSize) in
		let hexStrSize = hex_str_size(dataPtrSize.pointee)
		let buffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity:hexStrSize)
		defer {
			buffer.deallocate()
		}
		guard hex_encode(dataPtr, dataPtrSize.pointee, buffer.baseAddress, hexStrSize) == true else {
			throw Error.hexEncodeFailed
		}
		return String(cString:buffer.baseAddress!)
	}
}
public func hex_encode<O>(_ data:O) throws -> String where O:RAW_val {
	let hexStrSize = hex_str_size(data.RAW_size)
	let buffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity:hexStrSize)
	defer {
		buffer.deallocate()
	}
	try data.asRAW_val { (dataPtr, dataPtrSize) in
		guard hex_encode(dataPtr, dataPtrSize.pointee, buffer.baseAddress, hexStrSize) == true else {
			throw Error.hexEncodeFailed
		}
	}
	return String(cString:buffer.baseAddress!)
}