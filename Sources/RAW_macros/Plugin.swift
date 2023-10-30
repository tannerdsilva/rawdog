import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RAW_macros:CompilerPlugin {
	let providingMacros:[Macro.Type] = [
		FixedBuffer.self,
		FixedSizeBufferTypeMacro.self
	]
}