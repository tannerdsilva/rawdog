import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RAW_macros:CompilerPlugin {
	let providingMacros:[Macro.Type] = [
		RAW_staticbuff_macro.self,
		ConcatBufferTypeMacro.self,
	]
}