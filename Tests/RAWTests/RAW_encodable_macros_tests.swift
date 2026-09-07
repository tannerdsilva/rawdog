import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: #RAW_encode", .serialized)
struct RAW_encodable_decl_macro_tests {
	@Test
	func testRAW_encodable_decl_macro_valid_use() throws {
		assertMacroExpansion(
			"#RAW_encode_decl(RAW_staticbuff: FooBar.self, storage: \\._bytesWOW)",
			expandedSource:"""
			@RAW_encode_impl(RAW_staticbuff: FooBar.self, storage: \\._bytesWOW)
			borrowing func RAW_encode(_: UnsafeMutableRawPointer.Type, destination __encode__bytesWOW_to_here: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
			""",
			macroSpecs:["RAW_encode_decl": MacroSpec(type: RAW_encodable_protocol.DataMacro.self)],
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
			@RAW_encode_impl(RAW_staticbuff: FooBar.self, storage: \\._bytesWOW)
			borrowing func RAW_encode(_: UnsafeMutableRawPointer.Type, destination fooBarPooBar: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
			""",
			expandedSource:
			"""
			borrowing func RAW_encode(_: UnsafeMutableRawPointer.Type, destination fooBarPooBar: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
			    #RAW_accessible_encode(self, destination: fooBarPooBar)
			}
			""",
			macroSpecs:["RAW_encode_impl": MacroSpec(type: RAW_encodable_protocol.DataMacro.self)],
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
	func RAW_staticbuff_encode() async throws {
		assertMacroExpansion(
			"""
			#RAW_accessible_encode(self, destination: fooBarPooBar)
			""",
			expandedSource:
			"""
			self.RAW_access_immutable(UnsafeRawBufferPointer.self) { ptr in
				guard let src = ptr.baseAddress else {
				    return fooBarPooBar
				}
				return RAW_memcpy(fooBarPooBar, src, ptr.count) + ptr.count
			}
			""",
			macroSpecs:["RAW_accessible_encode": MacroSpec(type: RAW_staticbuff_encode_decl.self)],
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
			#RAW_accessible_encode(cliffordTheDog, destination: fooBarPooBar)
			""",
			expandedSource:
			"""
			cliffordTheDog.RAW_access_immutable(UnsafeRawBufferPointer.self) { ptr in
				guard let src = ptr.baseAddress else {
				    return fooBarPooBar
				}
				return RAW_memcpy(fooBarPooBar, src, ptr.count) + ptr.count
			}
			""",
			macroSpecs:["RAW_accessible_encode": MacroSpec(type: RAW_staticbuff_encode_decl.self)],
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