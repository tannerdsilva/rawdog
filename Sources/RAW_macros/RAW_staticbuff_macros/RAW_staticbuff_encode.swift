// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct RAW_staticbuff_encode_decl:ExpressionMacro {
	public static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
		guard node.arguments.count == 2 else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected 2 arguments in RAW_accessible_encode macro invocation, found \(node.arguments.count)."))
			context.diagnose(diagnostic)
			return ExprSyntax("()")
		}

		var nameToAccess:ExprSyntax? = nil
		var destinationPointerName:ExprSyntax? = nil
		for (i, arg) in node.arguments.enumerated() {
			switch i {
				case 0:
					nameToAccess = arg.expression
				case 1:
					destinationPointerName = arg.expression
				default:
					let diagnostic = Diagnostic(node:arg, message:InternalMacroFailure(message:"found more arguments than expected. expected 2, found at least \(i+1)."))
					context.diagnose(diagnostic)
					return ExprSyntax("()")
			}
		}
		guard let nameToAccess, let destinationPointerName else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"could not find the expected arguments in the macro invocation. expected an expression for the value to encode and an expression for the destination pointer."))
			context.diagnose(diagnostic)
			return ExprSyntax("()")
		}
		
		return ExprSyntax(
			"""
			\(raw:nameToAccess.trimmedDescription).RAW_access_immutable(UnsafeRawBufferPointer.self) { ptr in
				guard let src = ptr.baseAddress else { return \(raw:destinationPointerName.trimmedDescription) }
				return RAW_memcpy(\(raw:destinationPointerName.trimmedDescription), src, ptr.count) + ptr.count
			}
			"""
		)
	}
}
