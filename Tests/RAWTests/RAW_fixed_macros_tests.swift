import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

internal struct TestFailureSpecError:Swift.Error, CustomDebugStringConvertible {
	let message:String
	let path:String
	let line:Int
	let column:Int
	var debugDescription:String {
		return "File \(path), Line \(line), Column \(column): '\(message)'"
	}
}

@Suite("Macro: @RAW_fixed(concat:)", .serialized)
struct RAW_fixed_macro_concat_tests {
	@Test
	func testRAW_fixed_macro_concat_valid_use() throws {
		assertMacroExpansion(
			"@RAW_fixed(concat:Example1.self, Example2.self) struct Example {}",
			expandedSource:"""
			struct Example {}

			extension Example: RAW_fixed {
				#RAW_fixed_type(concat: Example1.self, Example2.self)
			}
			""",
			macroSpecs:["RAW_fixed": MacroSpec(type: RAW_macros.RAW_fixed_protocol.ConcatMacro.self, conformances:["RAW_fixed"])],
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

		var expectedMessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.ConcatMacro.self))", id:"\(String(describing:RAW_macros.RAW_fixed_protocol.ConcatMacro.MismatchedConcatTypes.self))")
		var expectedDiagnostic = DiagnosticSpec(id:expectedMessageID, message:"the concat types argument in the #RAW_fixed_type macro does not match the concat types argument in this macro. expected [\"Example1.self\", \"Example2.self\"], found [\"Example1.self\", \"Example2.self\", \"Example3.self\"].", line:3, column:26)
		assertMacroExpansion(
			"""
			@RAW_fixed(concat:Example1.self, Example2.self) 
			struct Example:RAW_fixed {
				#RAW_fixed_type(concat: Example1.self, Example2.self, Example3.self)
			}
			""",
			expandedSource:
			"""

			struct Example:RAW_fixed {
				#RAW_fixed_type(concat: Example1.self, Example2.self, Example3.self)
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_fixed": MacroSpec(type: RAW_macros.RAW_fixed_protocol.ConcatMacro.self, conformances:[])],
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

		expectedMessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.ConcatMacro.self))", id:"\(String(describing:RAW_macros.RAW_fixed_protocol.ConcatMacro.UnconfirmedConcatTypes.self))")
		expectedDiagnostic = DiagnosticSpec(id:expectedMessageID, message:"the concat types argument in the #RAW_fixed_type macro could not be confirmed to match the concat types argument in this macro. expected [\"Example1.self\", \"Example2.self\"]. implement the conformance of `RAW_fixed` on this member to resolve this error.", line:1, column:12)
		assertMacroExpansion(
			"""
			@RAW_fixed(concat:Example1.self, Example2.self) 
			struct Example {
			
			}
			""",
			expandedSource:
			"""
			
			struct Example {
			
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_fixed": MacroSpec(type: RAW_macros.RAW_fixed_protocol.ConcatMacro.self, conformances:[])],
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

@Suite("Macro: @RAW_fixed(bytes:)", .serialized)
struct RAW_fixed_macro_bytes_tests {
	@Test
	func testRAW_fixed_macro_bytes_valid_use() throws {
		assertMacroExpansion(
			"@RAW_fixed(bytes:5) struct Example {}",
			expandedSource:"""
			struct Example {}

			extension Example: RAW_fixed {
				#RAW_fixed_type(bytes: 5)
			}
			""",
			macroSpecs:["RAW_fixed": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:["RAW_fixed"])],
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

		var expectedMessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.BytesMacro.self))", id:"\(String(describing:RAW_macros.RAW_fixed_protocol.BytesMacro.MismatchedByteCount.self))")
		var expectedDiagnostic = DiagnosticSpec(id:expectedMessageID, message:"the byte count argument in the #RAW_fixed_type macro does not match the byte count argument in this macro. expected 5, found 7.", line:3, column:24)
		assertMacroExpansion(
			"""
			@RAW_fixed(bytes:5) 
			struct Example:RAW_fixed {
				#RAW_fixed_type(bytes:7)
			}
			""",
			expandedSource:
			"""

			struct Example:RAW_fixed {
				#RAW_fixed_type(bytes:7)
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_fixed": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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
			@RAW_fixed(bytes:5) 
			struct Example {
				#RAW_fixed_type(bytes:7)
			}
			""",
			expandedSource:
			"""

			struct Example {
				#RAW_fixed_type(bytes:7)
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_fixed": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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

		expectedMessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.BytesMacro.self))", id:"\(String(describing:RAW_macros.RAW_fixed_protocol.BytesMacro.UnconfirmedByteSize.self))")
		expectedDiagnostic = DiagnosticSpec(id:expectedMessageID, message:"the byte count argument in the #RAW_fixed_type macro could not be confirmed to match the byte count argument in this macro. expected 5. implement the conformance of `RAW_fixed` on this member to resolve this error.", line:1, column:12)
		assertMacroExpansion(
			"""
			@RAW_fixed(bytes:5) 
			struct Example {
			
			}
			""",
			expandedSource:
			"""
			
			struct Example {
			
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_fixed": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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

@Suite("Macro: #RAW_fixed_type(concat:)", .serialized)
struct RAW_fixed_type_macro_concat_tests {
	@Test
	func testRAW_fixed_type_concat_valid_use() throws {
		assertMacroExpansion(
			"#RAW_fixed_type(concat:Example1.self, Example2.self)",
			expandedSource: "typealias RAW_fixed_type = (Example1.RAW_fixed_type, Example2.RAW_fixed_type)",
			macroSpecs:["RAW_fixed_type": MacroSpec(type: RAW_macros.RAW_fixed_protocol.ConcatMacro.self, conformances:[])],
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

@Suite(
	"Macro: #RAW_fixed_type(bytes:)",
	.serialized
)
struct RAW_fixed_type_tests {
	@Test
	func testRAW_fixed_type_bytes_valid_use() throws {
		// test with 5 bytes
		assertMacroExpansion(
			"#RAW_fixed_type(bytes:5)",
			expandedSource: "typealias RAW_fixed_type = (UInt8, UInt8, UInt8, UInt8, UInt8)",
			macroSpecs:["RAW_fixed_type": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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

		// test with 16 bytes
		assertMacroExpansion(
			"#RAW_fixed_type(bytes:16)",
			expandedSource: "typealias RAW_fixed_type = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)",
			macroSpecs:["RAW_fixed_type": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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

		// test with 0 bytes
		assertMacroExpansion(
			"#RAW_fixed_type(bytes:0)",
			expandedSource: "typealias RAW_fixed_type = ()",
			macroSpecs:["RAW_fixed_type": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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

		// test with a positive prefix operator.
		assertMacroExpansion(
			"#RAW_fixed_type(bytes:+2)",
			expandedSource:"typealias RAW_fixed_type = (UInt8, UInt8)",
			macroSpecs:["RAW_fixed_type": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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

	@Test
	func testRAW_fixed_type_bytes_valid_invalidUse() throws {
		// test with a negative prefix operator.
		let expectedMessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.self))", id:"\(String(describing:RAW_macros.RAW_fixed_protocol.RAW_fixed_bytes_argument_validator.InvalidPrefixOperator.self))")
		let expectedDiagnostic = DiagnosticSpec(id:expectedMessageID, message:"invalid prefix operator '-' found in bytes argument expression. only positive integer literals are allowed.", line:1, column:23)
		assertMacroExpansion(
			"#RAW_fixed_type(bytes:-2)",
			expandedSource:"typealias RAW_fixed_type = ()",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_fixed_type": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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
		let expectedMessageID2 = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.self))", id:"\(String(describing:RAW_macros.RAW_fixed_protocol.RAW_fixed_bytes_argument_validator.FloatLiteralExpressionFound.self))")
		let expectedDiagnostic2 = DiagnosticSpec(id:expectedMessageID2, message:"float literal expressions are not allowed. only integer literals can be used to express the size of a `RAW_fixed_type`.", line:1, column:23)
		assertMacroExpansion(
			"#RAW_fixed_type(bytes:2.5)",
			expandedSource:"typealias RAW_fixed_type = ()",
			diagnostics: [expectedDiagnostic2],
			macroSpecs:["RAW_fixed_type": MacroSpec(type: RAW_macros.RAW_fixed_protocol.BytesMacro.self, conformances:[])],
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