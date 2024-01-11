import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RAW_macros:CompilerPlugin {
	let providingMacros:[Macro.Type] = [
		RAW_staticbuff_fixedwidthinteger_explicit_macro.self,
		RAW_staticbuff_macro.self,
		ConcatBufferTypeMacro.self,
	]
}