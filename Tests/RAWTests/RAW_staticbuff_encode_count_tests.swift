import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

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

