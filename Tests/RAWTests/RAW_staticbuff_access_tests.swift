import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

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

