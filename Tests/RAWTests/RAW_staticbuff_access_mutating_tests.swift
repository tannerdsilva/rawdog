import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

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

