// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct RAW_staticbuff_encode_count_decl:ExpressionMacro {
	public static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
		guard node.arguments.count == 1 else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected 1 argument in RAW_staticbuff_encode_count macro invocation, found \(node.arguments.count)."))
			context.diagnose(diagnostic)
			return ExprSyntax("()")
		}
		
		return ExprSyntax(
			"""
			count += MemoryLayout<RAW_fixed_type>.size
			"""
		)
	}
}
