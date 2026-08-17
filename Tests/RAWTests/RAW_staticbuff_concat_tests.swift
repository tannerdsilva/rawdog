import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: @RAW_staticbuff(concat:)", .serialized)
struct RAW_staticbuff_concat_tests {
	@Test("two types - generates member + extension with compare")
	func testStaticbuffConcatTwoTypes() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(concat: A.self, B.self)
			struct AB:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct AB:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(concat: A.self, B.self)

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

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(A.RAW_staticbuff_zeroed(), B.RAW_staticbuff_zeroed())
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}

				public static func RAW_compare(lhs_data: UnsafeRawPointer, lhs_count: size_t, rhs_data: UnsafeRawPointer, rhs_count: size_t) -> Int32 {
					var lhs_var = lhs_data;
					var rhs_var = rhs_data
					let b0 = A.RAW_compare(lhs_data: lhs_data, lhs_count: MemoryLayout<A>.size, rhs_data: rhs_data, rhs_count: MemoryLayout<A>.size)
					if b0 != 0 {
						return b0
					}
					lhs_var = lhs_var.advanced(by: MemoryLayout<A>.size)
					rhs_var = rhs_var.advanced(by: MemoryLayout<A>.size)
					let b1 = B.RAW_compare(lhs_data: lhs_var, lhs_count: MemoryLayout<B>.size, rhs_data: rhs_var, rhs_count: MemoryLayout<B>.size)
					if b1 != 0 {
						return b1
					}
					return 0
				}
			}

			extension AB: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
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

	@Test("extraneous instance variable emits diagnostic")
	func testStaticbuffConcatExtraneousVar() throws {
let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration"), message:"extraneous variable declaration found. instance variables are not supported in this configuration.", line:3, column:2, severity:.error, fixIts: [FixItSpec(message:"remove this instance variable."), FixItSpec(message:"convert this instance variable to a static variable.")])
		assertMacroExpansion(
			"""
			@RAW_staticbuff(concat: A.self, B.self)
			struct AB:RAW_staticbuff, RAW_decodable {
				var extra:Int = 0
			}
			""",
			expandedSource:
			"""

			struct AB:RAW_staticbuff, RAW_decodable {
				var extra:Int = 0
			}

			extension AB: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			diagnostics: [expectedDiagnostic],
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

	@Test("three types - generates compare with three sub-comparisons")
	func testStaticbuffConcatThreeTypes() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(concat: A.self, B.self, C.self)
			struct ABC:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct ABC:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(concat: A.self, B.self, C.self)

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

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(A.RAW_staticbuff_zeroed(), B.RAW_staticbuff_zeroed(), C.RAW_staticbuff_zeroed())
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}

				public static func RAW_compare(lhs_data: UnsafeRawPointer, lhs_count: size_t, rhs_data: UnsafeRawPointer, rhs_count: size_t) -> Int32 {
					var lhs_var = lhs_data;
					var rhs_var = rhs_data
					let b0 = A.RAW_compare(lhs_data: lhs_data, lhs_count: MemoryLayout<A>.size, rhs_data: rhs_data, rhs_count: MemoryLayout<A>.size)
					if b0 != 0 {
						return b0
					}
					lhs_var = lhs_var.advanced(by: MemoryLayout<A>.size)
					rhs_var = rhs_var.advanced(by: MemoryLayout<A>.size)
					let b1 = B.RAW_compare(lhs_data: lhs_var, lhs_count: MemoryLayout<B>.size, rhs_data: rhs_var, rhs_count: MemoryLayout<B>.size)
					if b1 != 0 {
						return b1
					}
					lhs_var = lhs_var.advanced(by: MemoryLayout<B>.size)
					rhs_var = rhs_var.advanced(by: MemoryLayout<B>.size)
					let b2 = C.RAW_compare(lhs_data: lhs_var, lhs_count: MemoryLayout<C>.size, rhs_data: rhs_var, rhs_count: MemoryLayout<C>.size)
					if b2 != 0 {
						return b2
					}
					return 0
				}
			}

			extension ABC: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
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

