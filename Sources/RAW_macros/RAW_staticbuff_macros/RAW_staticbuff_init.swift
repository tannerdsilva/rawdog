// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

internal struct RAW_staticbuff_protocol {
	internal struct InitMacro {}
}

extension RAW_staticbuff_protocol.InitMacro:ExpressionMacro {
	internal static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
		guard node.arguments.count == 3 else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected 3 arguments in RAW_staticbuff_init macro invocation, found \(node.arguments.count)."))
			context.diagnose(diagnostic)
			return ExprSyntax("()")
		}
		var memberAccessExpression:MemberAccessExprSyntax? = nil
		var firstExpression:ExprSyntax? = nil
		var lastName:DeclReferenceExprSyntax? = nil
		argLoop: for (i, arg) in node.arguments.enumerated() {
			switch i {
				case 0:
					memberAccessExpression = arg.expression.as(MemberAccessExprSyntax.self)
					if memberAccessExpression != nil, let base = memberAccessExpression!.base, base.trimmedDescription != "Self" {
						let diagnostic = Diagnostic(node:arg.expression, message:TypeMustBeSelfFailure(found:arg.expression.trimmedDescription), fixIts: [
							FixIt(message:TypeMustBeSelfFailure.FixIt(), changes:[
								.replace(oldNode: Syntax(arg.expression), newNode: Syntax(ExprSyntax("Self.self")))
							])
						])
						context.diagnose(diagnostic)
					}
					continue argLoop
				case 1:
					firstExpression = arg.expression
					continue argLoop
				case 2:
					let allNames = RAW_macro_validators.validateRAW_keypath_argument(labeledExpression:arg, context:context)
					guard let lastComponent = allNames?.last else {
						let diagnostic = Diagnostic(node:arg, message:InternalMacroFailure(message:"expected a valid key path expression in the third argument of RAW_staticbuff_init, but was not able to find one."))
						context.diagnose(diagnostic)
						return ExprSyntax("()")
					}
					lastName = lastComponent
					continue argLoop
				default:
					let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument index \(i) in RAW_staticbuff_init macro invocation."))
					context.diagnose(diagnostic)
					return ExprSyntax("()")
			}
		}
		guard let firstExpression, let lastName else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"could not parse all required arguments in RAW_staticbuff_init macro invocation."))
			context.diagnose(diagnostic)
			return ExprSyntax("()")
		}
		return ExprSyntax(
			"""
			\(raw:lastName) = \(raw:firstExpression).load(as:RAW_fixed_type.self)
			"""
		)
    }
}
