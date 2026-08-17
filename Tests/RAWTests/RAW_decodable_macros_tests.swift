import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: #RAW_decode", .serialized)
struct RAW_decodable_macro_tests {

	/// validate that the RAW_decode_decl macro works as expected when Self.self is used as the RAW_staticbuff type.
	/// - no diagnostics shall be thrown, therefore, no fixits shall be shown either.
	/// - the local variable name for the storage key-path shall be correctly carried from the macro declaration to the macro implementation.
	@Test("#RAW_decode_decl - basic valid use with `Self.self`")
	func testRAW_decodable_decl_macro_valid_use() throws {
		assertMacroExpansion(
			"#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytEs)",
			expandedSource:"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytEs)
			init?(RAW_decode __bufferarg__bytEs: UnsafeRawBufferPointer)
			""",
			macroSpecs:["RAW_decode_decl": MacroSpec(type:RAW_decodable_protocol.DecodeMacro.self)],
			indentationWidth: .tabs(1),
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

	/// validate that the RAW_decode_decl macro works as expected when Self.self is NOT used as the RAW_staticbuff type.
	/// - the code shall still expand as if the user did not use a non-Self type.
	/// - a diagnostics message shall be shown to indicate to the user that a syntax violation has been made and needs to be corrected.
	/// 	- the diagnostics error shall include a single 'FixIt' to allow the user an easy way to correct their problem.
	/// - the local variable name for the storage key-path shall be correctly carried from the macro declaration to the macro implementation, even in the case of a diagnostic being thrown.
	@Test("#RAW_decode_decl - invalid use with non-`Self` type")
	func testRAW_decodable_decl_macro_invalid_use() throws {
		assertMacroExpansion(
			"#RAW_decode_decl(RAW_staticbuff: Example.self, storage: \\._bytEs)",
			expandedSource:"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytEs)
			init?(RAW_decode __bufferarg__bytEs: UnsafeRawBufferPointer)
			""",
			diagnostics: [
				DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"type_must_be_self"), message:TypeMustBeSelfFailure(found:"Example.self").message, line:1, column:34, fixIts: [
					FixItSpec(message:TypeMustBeSelfFailure.FixIt().message)
				])
			],
			macroSpecs: ["RAW_decode_decl":MacroSpec(type:RAW_decodable_protocol.DecodeMacro.self)],
			applyFixIts: [TypeMustBeSelfFailure.FixIt().message],
			fixedSource: """
			#RAW_decode_decl(RAW_staticbuff: Self.self, storage: \\._bytEs)
			""",
			indentationWidth: .tabs(1),
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

	/// validate that the RAW_decode_impl macro works as expected when Self.self is used as the RAW_staticbuff type.
	/// - no diagnostics shall be thrown, therefore, no fixits shall be shown either.
	/// - the macro shall expand the code as expected
	/// - the local variable name for the `RAW_decode`` variable shall be properly parsed and reused in the expanded source
	@Test("#RAW_decode_impl - basic valid use with `Self.self`")
	func testRAW_decodable_impl_macro_valid_use() throws {
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytEs)
			init?(RAW_decode __bufferarg__bytEs: UnsafeRawBufferPointer)
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytEs: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytEs, storage: \\._bytEs)
			}
			""",
			macroSpecs: ["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
			indentationWidth: .tabs(1),
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

	@Test("#RAW_decode_impl - invalid use with non-`Self` type")
	func testRAW_decodable_impl_macro_invalid_use() throws {
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: FooPar.self, storage: \\._bytEs)
			init?(RAW_decode __bufferarg__bytEs: UnsafeRawBufferPointer)
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytEs: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytEs, storage: \\._bytEs)
			}
			""",
			diagnostics: [
				DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"type_must_be_self"), message:TypeMustBeSelfFailure(found:"FooPar.self").message, line:1, column:34, fixIts: [
					FixItSpec(message:TypeMustBeSelfFailure.FixIt().message)
				])
			],
			macroSpecs:["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
			applyFixIts: [TypeMustBeSelfFailure.FixIt().message],
			fixedSource:"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytEs)
			init?(RAW_decode __bufferarg__bytEs: UnsafeRawBufferPointer)
			""",
			indentationWidth: .tabs(1),
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

	@Test("#RAW_decode_impl - test sub-macro argument auto-fill")
	func testRAW_decodable_impl_macro_multiple_macro_use() throws {
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init()
			}
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
			    #RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
			}
			""",
			macroSpecs:["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
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

	@Test("#RAW_decode_impl - test sub-macro auto-fill and multiple use diagnostic (with fix-it application)")
	func testRAW_decodable_impl_macro_multiple_macro_use_diagnostic() throws {
		let expectedMessageID = MessageID(domain: "RAW_decodable_protocol", id: "multiple_macro_usage_diag")
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:expectedMessageID, message:RAW_decodable_protocol.DecodeMacro.MultipleMacroUsageDiagnostic().message, line:4, column:2, fixIts: [
			FixItSpec(message:RAW_decodable_protocol.DecodeMacro.MultipleMacroUsageDiagnostic.FixIt().message)
		])
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
			    #RAW_staticbuff_init()
				#RAW_staticbuff_init(ohThisDefinitelyIsntTheCorrectBufferArgument)
			}
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
				#RAW_staticbuff_init(ohThisDefinitelyIsntTheCorrectBufferArgument)
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
			applyFixIts: [],
			indentationWidth: .tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			},
			
		)
		// test the fixit application
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init()
				#RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
			}
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
				#RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
			applyFixIts: [RAW_decodable_protocol.DecodeMacro.MultipleMacroUsageDiagnostic.FixIt().message],
			fixedSource: """
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init()
			}
			""",
			indentationWidth: .tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			},
			
		)
	}

	@Test("#RAW_decode_impl - test sub-macro auto-fill")
	func testRAW_decodable_impl_macro_multiple_macro_use_with_other_content() throws {
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				#RAW_staticbuff_init(ohThisDefinitelyIsntTheCorrectBufferArgument)
			}
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
			    #RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
			}
			""",
			macroSpecs:["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
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

	@Test("#RAW_decode_impl - test sub-macro auto-fill with content before the initializer")
	func testRAW_decodable_impl_macro_multiple_macro_use_with_other_content_before() throws {
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				print("oh here we go again")
			}
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
			    print("oh here we go again")
			    #RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
			}
			""",
			macroSpecs:["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
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

	@Test("#RAW_decode_impl - test sub-macro auto-fill with content before and after the initializer")
	func testRAW_decodable_impl_macro_multiple_macro_use_with_other_content_before_and_after() throws {
		assertMacroExpansion(
			"""
			@RAW_decode_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
				print("oh here we go again")
				print("this is content before the initializer macro")
				#RAW_staticbuff_init()
				print("this is content")
				print("that goes after the initializer macro")
			}
			""",
			expandedSource:"""
			init?(RAW_decode __bufferarg__bytes: UnsafeRawBufferPointer) {
			    print("oh here we go again")
			    print("this is content before the initializer macro")
			    #RAW_staticbuff_init(Self.self, RAW_decode: __bufferarg__bytes, storage: \\._bytes)
			    print("this is content")
			    print("that goes after the initializer macro")
			}
			""",
			macroSpecs:["RAW_decode_impl": MacroSpec(type: RAW_decodable_protocol.DecodeMacro.self)],
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