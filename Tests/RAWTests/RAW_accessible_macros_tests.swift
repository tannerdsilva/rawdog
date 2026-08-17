import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: #RAW_accessible", .serialized)
struct RAW_accessible_macro_tests {

	@Test("#RAW_access_immutable_decl - basic valid usage with Self.self type")
	func testRAW_access_immutable_decl_proper_usage() throws {
		assertMacroExpansion(
			"#RAW_access_immutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)",
			expandedSource:"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			macroSpecs:["RAW_access_immutable_decl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
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

	@Test("#RAW_access_immutable_decl - basic invalid usage with non-Self type")
	func testRAW_access_immutable_decl_improper_usage() throws {
		let expectedMessageID = MessageID(domain: "RAW_macros", id: "type_must_be_self")
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:expectedMessageID, message:RAW_macros.TypeMustBeSelfFailure(found:"FooBar.self").message, line:1, column:44, fixIts: [
			FixItSpec(message:RAW_macros.TypeMustBeSelfFailure.FixIt().message)
		])
		assertMacroExpansion(
			"#RAW_access_immutable_decl(RAW_staticbuff: FooBar.self, storage: \\._bytes)",
			expandedSource:"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_immutable_decl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
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
	
	@Test("@RAW_access_immutable_impl - basic valid usage with Self.self type")
	func testRAW_access_immutable_impl_proper_usage() throws {
		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
			    return #RAW_staticbuff_access(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
			}
			""",
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
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

	@Test("@RAW_access_immutable_impl - invalid use with non-`Self` type")
	func testRAW_access_immutable_impl_improper_usage() throws {
		let expectedMessageID = MessageID(domain: "RAW_macros", id: "type_must_be_self")
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:expectedMessageID, message:RAW_macros.TypeMustBeSelfFailure(found:"FooBar.self").message, line:1, column:44, fixIts: [
			FixItSpec(message:RAW_macros.TypeMustBeSelfFailure.FixIt().message)
		])

		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: FooBar.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
			    return #RAW_staticbuff_access(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
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
	
	@Test("@RAW_access_immutable_impl - test sub-macro argument auto-fill")
	func testRAW_access_immutable_impl_argument_autofill() throws {
		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access()
				return x
			}
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
			    let x = #RAW_staticbuff_access(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
			    return x
			}
			""",
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
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
		
		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access()
			}
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
			    return #RAW_staticbuff_access(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
			}
			""",
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
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
	
	@Test("@RAW_access_immutable_impl - invalid RAW_access_immutable function signature (with fix-it application)")
	func testRAW_access_immutable_impl_invalid_function() throws {
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:MessageID(domain:"RAW_accessible_protocol", id:"invalid_function_diag"), message:RAW_accessible_protocol.ImmutableMacro.InvalidFunctionDiagnostic().message, line:1, column:1, fixIts: [
			FixItSpec(message:RAW_accessible_protocol.ImmutableMacro.InvalidFunctionDiagnostic.FixIt().message)
		])
		let fixedSource = """
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access()
			}
			"""
		
		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, thisShouldHaveTwoNames: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access()
			}
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, thisShouldHaveTwoNames: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.ImmutableMacro.InvalidFunctionDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
		
		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access()
			}
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.ImmutableMacro.InvalidFunctionDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
		
		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable() {
				return #RAW_staticbuff_access()
			}
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable() {
				return #RAW_staticbuff_access()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.ImmutableMacro.InvalidFunctionDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
	
	@Test("@RAW_access_immutable_impl - multiple use diagnostic (with fix-it application)")
	func testRAW_access_immutable_impl_multiple_macro_use() throws {
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:MessageID(domain:"RAW_accessible_protocol", id:"multiple_macro_usage_diag"), message:RAW_accessible_protocol.ImmutableMacro.MultipleMacroUsageDiagnostic().message, line:4, column:9, fixIts: [
			FixItSpec(message:RAW_accessible_protocol.ImmutableMacro.MultipleMacroUsageDiagnostic.FixIt().message)
		])
		let fixedSource = """
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access()
			}
			"""
		
		assertMacroExpansion(
			"""
			@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access()
				return #RAW_staticbuff_access()
			}
			""",
			expandedSource:"""
			borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
				return #RAW_staticbuff_access()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_immutable_impl": MacroSpec(type: RAW_accessible_protocol.ImmutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.ImmutableMacro.MultipleMacroUsageDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
	
	@Test("#RAW_access_mutable_decl - basic valid usage with Self.self type")
	func testRAW_access_mutable_decl_proper_usage() throws {
		assertMacroExpansion(
			"#RAW_access_mutable_decl(RAW_staticbuff: Self.self, storage: \\._bytes)",
			expandedSource:"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			macroSpecs:["RAW_access_mutable_decl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
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

	@Test("#RAW_access_mutable_decl - basic invalid usage with non-Self type")
	func testRAW_access_mutable_decl_improper_usage() throws {
		let expectedMessageID = MessageID(domain: "RAW_macros", id: "type_must_be_self")
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:expectedMessageID, message:RAW_macros.TypeMustBeSelfFailure(found:"FooBar.self").message, line:1, column:42, fixIts: [
			FixItSpec(message:RAW_macros.TypeMustBeSelfFailure.FixIt().message)
		])
		assertMacroExpansion(
			"#RAW_access_mutable_decl(RAW_staticbuff: FooBar.self, storage: \\._bytes)",
			expandedSource:"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_mutable_decl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
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
	
	@Test("@RAW_access_mutable_impl - basic valid usage with Self.self type")
	func testRAW_access_mutable_impl_proper_usage() throws {
		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			expandedSource:"""
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
			}
			""",
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
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

	@Test("@RAW_access_mutable_impl - invalid use with non-`Self` type")
	func testRAW_access_mutable_impl_improper_usage() throws {
		let expectedMessageID = MessageID(domain: "RAW_macros", id: "type_must_be_self")
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:expectedMessageID, message:RAW_macros.TypeMustBeSelfFailure(found:"FooBar.self").message, line:1, column:42, fixIts: [
			FixItSpec(message:RAW_macros.TypeMustBeSelfFailure.FixIt().message)
		])

		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: FooBar.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error
			""",
			expandedSource:"""
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
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
	
	@Test("@RAW_access_mutable_impl - test sub-macro argument auto-fill")
	func testRAW_access_mutable_impl_argument_autofill() throws {
		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access_mutating()
				return x
			}
			""",
			expandedSource:"""
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access_mutating(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
				return x
			}
			""",
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
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
		
		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating()
			}
			""",
			expandedSource:"""
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
			}
			""",
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
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
	
	@Test("@RAW_access_mutable_impl - invalid RAW_access_mutable function signature (with fix-it application)")
	func testRAW_access_mutable_impl_invalid_function() throws {
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:MessageID(domain:"RAW_accessible_protocol", id:"invalid_function_diag"), message:RAW_accessible_protocol.MutableMacro.InvalidFunctionDiagnostic().message, line:1, column:1, fixIts: [
			FixItSpec(message:RAW_accessible_protocol.MutableMacro.InvalidFunctionDiagnostic.FixIt().message)
		])
		let fixedSource = """
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating()
			}
			"""
		
		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, thisShouldHaveTwoNames: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating()
			}
			""",
			expandedSource:"""
			mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, thisShouldHaveTwoNames: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.MutableMacro.InvalidFunctionDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
		
		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating()
			}
			""",
			expandedSource:"""
			mutating func RAW_access_mutable(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				return #RAW_staticbuff_access_mutating()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.MutableMacro.InvalidFunctionDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
		
		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			mutating func RAW_access_mutable() {
				return #RAW_staticbuff_access_mutating()
			}
			""",
			expandedSource:"""
			mutating func RAW_access_mutable() {
				return #RAW_staticbuff_access_mutating()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.MutableMacro.InvalidFunctionDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
	
	@Test("@RAW_access_mutable_impl - multiple use diagnostic (with fix-it application)")
	func testRAW_access_mutable_impl_multiple_macro_use() throws {
		let expectedDiagnostic: DiagnosticSpec = DiagnosticSpec(id:MessageID(domain:"RAW_accessible_protocol", id:"multiple_macro_usage_diag"), message:RAW_accessible_protocol.MutableMacro.MultipleMacroUsageDiagnostic().message, line:4, column:9, fixIts: [
			FixItSpec(message:RAW_accessible_protocol.MutableMacro.MultipleMacroUsageDiagnostic.FixIt().message)
		])
		let fixedSource = """
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access_mutating()
			}
			"""
		
		assertMacroExpansion(
			"""
			@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\._bytes)
			borrowing func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access_mutating()
				return #RAW_staticbuff_access_mutating()
			}
			""",
			expandedSource:"""
			borrowing func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				let x = #RAW_staticbuff_access_mutating(self, storage: \\._bytes, bodyReturnType: R.self, bodyThrowsType: E.self, body: __body_to_pass__bytes_argument)
				return #RAW_staticbuff_access_mutating()
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_access_mutable_impl": MacroSpec(type: RAW_accessible_protocol.MutableMacro.self)],
			applyFixIts: [RAW_accessible_protocol.MutableMacro.MultipleMacroUsageDiagnostic.FixIt().message],
			fixedSource: fixedSource,
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
}
