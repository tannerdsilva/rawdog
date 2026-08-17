import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: @RAW_staticbuff(bytes:)", .serialized)
struct RAW_staticbuff_bytes_tests {
	@Test("bytes:5 - generates member + extension")
	func testStaticbuffBytesValid() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(bytes: 5)

				var _bytes: RAW_fixed_type

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
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

	@Test("bytes:1 - single byte type")
	func testStaticbuffBytesSingle() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 1)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(bytes: 1)

				var _bytes: RAW_fixed_type

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
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

	@Test("bytes:16 - sixteen byte type")
	func testStaticbuffBytesSixteen() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 16)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(bytes: 16)

				var _bytes: RAW_fixed_type

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
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

	@Test("extraneous instance variable emits diagnostic")
	func testStaticbuffBytesExtraneousVar() throws {
let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration"), message:"extraneous variable declaration found. instance variables are not supported in this configuration.", line:3, column:2, severity:.error, fixIts: [FixItSpec(message:"remove this instance variable."), FixItSpec(message:"convert this instance variable to a static variable.")])
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var extra:Int = 0
			}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var extra:Int = 0
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			diagnostics: [expectedDiagnostic],
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

	@Test("static variables are allowed")
	func testStaticbuffBytesStaticVar() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				static let foo = 42
			}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				static let foo = 42

				#RAW_fixed_type(bytes: 5)

				var _bytes: RAW_fixed_type

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
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

	@Test("computed properties are allowed")
	func testStaticbuffBytesComputedVar() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var computed:Int { return 42 }
			}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var computed:Int { return 42 }

				#RAW_fixed_type(bytes: 5)

				var _bytes: RAW_fixed_type

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
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
}

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

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

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

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

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

@Suite("Macro: #RAW_staticbuff_access", .serialized)
struct RAW_staticbuff_access_tests {
	@Test("valid expansion")
	func testStaticbuffAccessValid() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_access(instance, storage: \\._bytes, bodyReturnType: UnsafeRawBufferPointer.self, bodyThrowsType: Never.self, bodyArgument: someBody)
			""",
			expandedSource:
			"""
			try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<Self.RAW_fixed_type>) throws(Never) -> UnsafeRawBufferPointer in
				return try someBody(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<Self.RAW_fixed_type>.size))
			}
			""",
			macroSpecs:["RAW_staticbuff_access": MacroSpec(type: RAW_staticbuff_access_decl.self)],
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

@Suite("Macro: #RAW_staticbuff_access_mutating", .serialized)
struct RAW_staticbuff_access_mutating_tests {
	@Test("valid expansion")
	func testStaticbuffAccessMutatingValid() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_access_mutating(instance, storage: \\._bytes, bodyReturnType: UnsafeMutableRawBufferPointer.self, bodyThrowsType: Never.self, bodyArgument: someBody)
			""",
			expandedSource:
			"""
			try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<Self.RAW_fixed_type>) throws (Never) -> (UnsafeMutableRawBufferPointer) in
				return try someBody(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<Self.RAW_fixed_type>.size))
			}
			""",
			macroSpecs:["RAW_staticbuff_access_mutating": MacroSpec(type: RAW_staticbuff_access_mutating_decl.self)],
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

@Suite("Macro: #RAW_staticbuff_encode_count", .serialized)
struct RAW_staticbuff_encode_count_tests {
	@Test("valid expansion")
	func testStaticbuffEncodeCountValid() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_encode_count(count)
			""",
			expandedSource:
			"""
			count += MemoryLayout<RAW_fixed_type>.size
			""",
			macroSpecs:["RAW_staticbuff_encode_count": MacroSpec(type: RAW_staticbuff_encode_count_decl.self)],
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

@Suite("Macro: #RAW_staticbuff_fixedwidthinteger_type", .serialized)
struct RAW_staticbuff_fixedwidthinteger_type_tests {
	@Test("UInt32(bigEndian:true) - generates RAW_native() and init(RAW_native:)")
	func testFixedWidthIntegerUInt32BigEndian() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
			""",
			expandedSource:
			"""
			func RAW_native() -> UInt32 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt32>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt32(bigEndian: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt32.self))
				}
			}
			init(RAW_native native: UInt32) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bigEndian
				self.init(RAW_staticbuff: &enc)
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("UInt32(bigEndian:false) - uses littleEndian")
	func testFixedWidthIntegerUInt32LittleEndian() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:false)
			""",
			expandedSource:
			"""
			func RAW_native() -> UInt32 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt32>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt32(littleEndian: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt32.self))
				}
			}
			init(RAW_native native: UInt32) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.littleEndian
				self.init(RAW_staticbuff: &enc)
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("UInt8(bigEndian:true) - 1-byte uses `load` instead of `loadUnaligned`")
	func testFixedWidthIntegerUInt8() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:true)
			""",
			expandedSource:
			"""
			func RAW_native() -> UInt8 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt8>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt8(bigEndian: UnsafeRawPointer(selfPtr).load(as: UInt8.self))
				}
			}
			init(RAW_native native: UInt8) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bigEndian
				self.init(RAW_staticbuff: &enc)
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("UInt64(bigEndian:true) - 8-byte uses loadUnaligned")
	func testFixedWidthIntegerUInt64() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
			""",
			expandedSource:
			"""
			func RAW_native() -> UInt64 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt64>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt64(bigEndian: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt64.self))
				}
			}
			init(RAW_native native: UInt64) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bigEndian
				self.init(RAW_staticbuff: &enc)
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("missing generic type parameter emits diagnostic")
	func testFixedWidthIntegerMissingGeneric() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"expected a generic type parameter, e.g. <UInt32>", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type(bigEndian:true)
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("missing bigEndian argument emits diagnostic")
	func testFixedWidthIntegerMissingBigEndian() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"expected a 'bigEndian' argument, e.g. bigEndian:true", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>()
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("non-boolean bigEndian value emits diagnostic")
	func testFixedWidthIntegerNonBoolBigEndian() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"the 'bigEndian' argument must be a boolean literal (true or false)", line:1, column:48, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:42)
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

@Suite("Macro: #RAW_staticbuff_binaryfloatingpoint_type", .serialized)
struct RAW_staticbuff_binaryfloatingpoint_type_tests {
	@Test("Float - generates RAW_native() and init(RAW_native:)")
	func testBinaryFloatingPointFloat() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Float>()
			""",
			expandedSource:
			"""
			func RAW_native() -> Float {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Float>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return Float(bitPattern: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt32.self))
				}
			}
			init(RAW_native native: Float) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bitPattern
				self.init(RAW_staticbuff: &enc)
			}
			""",
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
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

	@Test("Double - generates RAW_native() and init(RAW_native:)")
	func testBinaryFloatingPointDouble() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Double>()
			""",
			expandedSource:
			"""
			func RAW_native() -> Double {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Double>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return Double(bitPattern: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt64.self))
				}
			}
			init(RAW_native native: Double) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bitPattern
				self.init(RAW_staticbuff: &enc)
			}
			""",
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
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

	@Test("Float16 - generates RAW_native() and init(RAW_native:)")
	func testBinaryFloatingPointFloat16() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Float16>()
			""",
			expandedSource:
			"""
			func RAW_native() -> Float16 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Float16>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return Float16(bitPattern: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt16.self))
				}
			}
			init(RAW_native native: Float16) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bitPattern
				self.init(RAW_staticbuff: &enc)
			}
			""",
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
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

	@Test("unsupported type emits diagnostic")
	func testBinaryFloatingPointUnsupportedType() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"unsupported BinaryFloatingPoint type: Float80. Supported types: Float, Double, Float16", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Float80>()
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
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

	@Test("missing generic type parameter emits diagnostic")
	func testBinaryFloatingPointMissingGeneric() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"expected a generic type parameter, e.g. <Float>", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type()
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
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

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
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

				#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(A.RAW_staticbuff_zeroed())
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

