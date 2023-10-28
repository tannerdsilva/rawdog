import struct CRAW.rawval_t;
import func CRAW.rawval_init;

// primary implementation of the ``RAW_val`` protocol on our generic rawval_t.
extension rawval_t:RAW_val {
	public var RAW_data:UnsafeRawPointer? {
		return self.rawval_data
	}
	public var RAW_size:UInt64 {
		return self.rawval_size
	}
}