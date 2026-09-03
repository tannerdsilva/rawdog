// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct RAW_staticbuff_access_mutating_decl:ExpressionMacro {
	fileprivate static let expectedArgumentCount = 5
	public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
		guard node.arguments.count == expectedArgumentCount else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected \(expectedArgumentCount) arguments in RAW_staticbuff_access_mutating macro invocation, found \(node.arguments.count)."))
			context.diagnose(diagnostic)
			return ExprSyntax("()")
		}
		var bodyReturnType:MemberAccessExprSyntax? = nil
		var bodyThrowsType:MemberAccessExprSyntax? = nil
		var bodyArgumentReference:DeclReferenceExprSyntax? = nil
		var storageName: DeclReferenceExprSyntax? = nil
		argLoop: for (i, arg) in node.arguments.enumerated() {
			switch i {
				case 0:
					// argument zero is the instance reference. it is validated for API symmetry
					// with the macro signature but is never emitted by this expansion.
					continue argLoop
				case 1:
					let allNames = RAW_macro_validators.validateRAW_keypath_argument(labeledExpression:arg, context:context)
					guard let lastComponent = allNames?.last else {
						let diagnostic = Diagnostic(node:arg, message:InternalMacroFailure(message:"expected a valid key path expression in the second argument of RAW_staticbuff_access_mutating, but was not able to find one."))
						context.diagnose(diagnostic)
						return ExprSyntax("()")
					}
					storageName = lastComponent
					continue argLoop
				case 2:
					bodyReturnType = arg.expression.as(MemberAccessExprSyntax.self)
					continue argLoop
				case 3:
					bodyThrowsType = arg.expression.as(MemberAccessExprSyntax.self)
					continue argLoop
				case 4:
					bodyArgumentReference = arg.expression.as(DeclReferenceExprSyntax.self)
					continue argLoop
				default:
					let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument index \(i) in RAW_staticbuff_access_mutating macro invocation."))
					context.diagnose(diagnostic)
					return ExprSyntax("()")
			}
		}
		guard let bodyReturnType, let bodyThrowsType, let bodyArgumentReference, let storageName else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"could not parse all required arguments in RAW_staticbuff_access_mutating macro invocation."))
			context.diagnose(diagnostic)
			return ExprSyntax("()")
		}
		return ExprSyntax(
			"""
			try withUnsafeMutablePointer(to: &\(raw:storageName.trimmedDescription)) { (ptr: UnsafeMutablePointer<Self.RAW_fixed_type>) throws (\(raw:bodyThrowsType.base!)) -> (\(raw:bodyReturnType.base!)) in
				return try \(raw:bodyArgumentReference)(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<Self.RAW_fixed_type>.size))
			}
			"""
		)
	}
}
