import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: Edge cases", .serialized)
struct RAW_staticbuff_edge_case_tests {
	@Test("@RAW_staticbuff(bytes: 0) - zero-length type generates empty tuple")
	func testStaticbuffBytesZero() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 0)
			struct Empty:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct Empty:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(bytes: 0)

				var _bytes: RAW_fixed_type

				public init?(RAW_decode bytes: UnsafeRawBufferPointer) {
				    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else {
				    	return nil
				    }
				    self = bytes.load(as: Self.self)
				}

				public borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "access the stored RAW_fixed_type via init(RAW_staticbuff:) instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "construct a zeroed instance from a zeroed RAW_fixed_type via init(RAW_staticbuff:) instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					()
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension Empty: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.BytesMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
			indentationWidth:.tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			}
		)
	}

	@Test("@RAW_staticbuff(concat: A.self) - single type concat")
	func testStaticbuffConcatSingleType() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(concat: A.self)
			struct JustA:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""
			struct JustA:RAW_staticbuff, RAW_decodable {
			
				#RAW_fixed_type(concat: A.self)
			
				var _bytes: RAW_fixed_type
			
				public init?(RAW_decode bytes: UnsafeRawBufferPointer) {
				    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else {
				    	return nil
				    }
				    self = bytes.load(as: Self.self)
				}
			
				public borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}
			
				public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}
			
				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}
			
				@available(*, deprecated, message: "access the stored RAW_fixed_type via init(RAW_staticbuff:) instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}
			
				@available(*, deprecated, message: "construct a zeroed instance from a zeroed RAW_fixed_type via init(RAW_staticbuff:) instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(A.RAW_staticbuff_zeroed())
				}
			
				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			
				public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
					var lhs_seeker = lhs_data
					var rhs_seeker = rhs_data
									let b0 = A.RAW_compare(lhs_data: lhs_seeker, rhs_data: rhs_seeker)
									if b0 != 0 {
						return b0
					}
					return 0
				}
			}
			
			extension JustA: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.ConcatMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
			indentationWidth:.tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			}
		)
	}
}

