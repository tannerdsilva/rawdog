// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Tools
internal struct RAW_decodable_protocol {
	internal struct DecodeMacro {
		internal struct InitializerFunctionRequirementDiagnostic:Swift.Error, DiagnosticMessage {
			internal let message:String = "RAW_decode_init macro must be attached to an initializer function declaration."
			internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_incorrect_modifier")
			internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		}

		internal struct MultipleMacroUsageDiagnostic:Swift.Error, DiagnosticMessage {
			internal let message:String = "RAW_staticbuff_init macro can only be used once in the body of an initializer."
			internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_decodable_protocol", id:"multiple_macro_usage_diag")
			internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			internal struct FixIt:FixItMessage {
				internal let message:String = "remove the duplicate usage of the #RAW_staticbuff_init macro."
				internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_decodable_protocol", id:"multiple_macro_usage_fixit")
			}
		}

		internal final class MacroArgumentRewriter:SwiftSyntax.SyntaxRewriter {
			let rawStaticbuffType:MemberAccessExprSyntax
			let bufferParameterName:TokenSyntax
			let storageKeyPath:DeclReferenceExprSyntax
			init(rawStaticbuffType:MemberAccessExprSyntax, bufferParameterName:TokenSyntax, storageKeyPath:DeclReferenceExprSyntax) {
				self.rawStaticbuffType = rawStaticbuffType
				self.bufferParameterName = bufferParameterName
				self.storageKeyPath = storageKeyPath
				super.init(viewMode:.fixedUp)
			}
			override func visit(_ _:LabeledExprListSyntax) -> LabeledExprListSyntax {
				var newList = [LabeledExprSyntax]()
				newList.append(
					LabeledExprSyntax(expression:rawStaticbuffType, trailingComma:TokenSyntax.commaToken()))
				newList.append(
					LabeledExprSyntax(label:TokenSyntax.identifier("RAW_decode"), colon:.colonToken(), expression:DeclReferenceExprSyntax(baseName:self.bufferParameterName), trailingComma:TokenSyntax.commaToken()))
				
				let keyPathLabeledExpr = LabeledExprSyntax(label:TokenSyntax.identifier("storage"), colon:.colonToken(), expression:KeyPathExprSyntax(backslash:.backslashToken(), components:KeyPathComponentListSyntax([KeyPathComponentSyntax(period:.periodToken(), component:.property(KeyPathPropertyComponentSyntax(declName:storageKeyPath)))])))
				newList.append(keyPathLabeledExpr)
				return LabeledExprListSyntax(newList)
			}
		}
	}
}

// MARK: - Declaration (Freestanding)
extension RAW_decodable_protocol.DecodeMacro:DeclarationMacro {
	internal static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard node.arguments.count == 2 else {
			// if there are not exactly two labeled expressions in the macro invocation, we should not generate any code.
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected exactly two arguments in the macro invocation, found \(node.arguments.count)."))
			context.diagnose(diagnostic)
			return []
		}
		var firstExpression:ExprSyntax? = nil
		var lastName:DeclReferenceExprSyntax? = nil
		argLoop: for (i, arg) in node.arguments.enumerated() {
			switch i {
				case 0:
					firstExpression = arg.expression
					continue argLoop
				case 1:
					let allNames = RAW_macro_validators.validateRAW_keypath_argument(labeledExpression:arg, context:context)
					guard let lastComponent = allNames?.last else {
						// if we were not able to find any valid key path components in the second argument, we should not generate any code.
						let diagnostic = Diagnostic(node:arg, message:InternalMacroFailure(message:"expected a valid key path expression in the second argument, but was not able to find one."))
						context.diagnose(diagnostic)
						return []
					}
					lastName = lastComponent
					continue argLoop
				default:
					let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument index \(i) found while parsing macro arguments. expected exactly two arguments."))
					context.diagnose(diagnostic)
					return []
			}
		}
		guard let firstExpression = firstExpression?.as(MemberAccessExprSyntax.self), let feBase = firstExpression.base, let lastName else {
			// if we were not able to find the first expression or the key path expression list, we should not generate any code.
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected a valid first expression and key path expression, but was not able to find them."))
			context.diagnose(diagnostic)
			return []
		}
		if feBase.trimmedDescription != "Self" {
			// if the first expression is not a member access expression with a base of `Self`, then we should not generate any code.
			let diagnostic = Diagnostic(node:firstExpression, message:TypeMustBeSelfFailure(found:firstExpression.trimmedDescription), fixIts: [
				FixIt(message:TypeMustBeSelfFailure.FixIt(), changes:[
					.replace(oldNode: Syntax(feBase), newNode: Syntax(IdentifierTypeSyntax(name:TokenSyntax.identifier("Self"))))
				])
			])
			context.diagnose(diagnostic)
		}
		return [
			DeclSyntax(
				"""
				@RAW_decode_impl(RAW_staticbuff:Self.self, storage:\\.\(raw:lastName))
				init?(RAW_decode __bufferarg_\(raw:lastName):UnsafeRawBufferPointer)
				"""
			)
		]
	}
}


// MARK: - Body (Attached))
extension RAW_decodable_protocol.DecodeMacro:BodyMacro {
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
		guard case let .argumentList(args) = node.arguments, args.count == 2 else {
			// if there are not exactly one argument in the macro, we should not generate any code.
			return []
		}
		var firstExpression:MemberAccessExprSyntax? = nil
		var lastName:DeclReferenceExprSyntax? = nil
		argLoop: for (i, arg) in args.enumerated() {
			switch i {
				case 0:
					firstExpression = arg.expression.as(MemberAccessExprSyntax.self)
					continue argLoop
				case 1:
					let allNames = RAW_macro_validators.validateRAW_keypath_argument(labeledExpression:arg, context:context)
					guard let lastComponent = allNames?.last else {
						// if we were not able to find any valid key path components in the second argument, we should not generate any code.
						let diagnostic = Diagnostic(node:arg, message:InternalMacroFailure(message:"expected a valid key path expression in the second argument, but was not able to find one."))
						context.diagnose(diagnostic)
						return []
					}
					lastName = lastComponent
					continue argLoop
				default:
					let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument index \(i) found while parsing macro arguments. expected exactly two arguments."))
					context.diagnose(diagnostic)
					return []
			}
		}
		guard let firstExpression, let feBase = firstExpression.base, let lastName else {
			// if we were not able to find the first expression or the key path expression list, we should not generate any code.
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected a valid first expression and key path expression, but was not able to find them."))
			context.diagnose(diagnostic)
			return []
		}
		if feBase.trimmedDescription != "Self" {
			// if the first expression is not a member access expression with a base of `Self`, then we should not generate any code.
			let diagnostic = Diagnostic(node:firstExpression, message:TypeMustBeSelfFailure(found:firstExpression.trimmedDescription), fixIts: [
				FixIt(message:TypeMustBeSelfFailure.FixIt(), changes:[
					.replace(oldNode: Syntax(feBase), newNode: Syntax(IdentifierTypeSyntax(name:TokenSyntax.identifier("Self"))))
				])
			])
			context.diagnose(diagnostic)
		}
		
		// parse the existing function declaration to determine how to generate the body of the initializer.
		guard let funcDeclaration = declaration.as(InitializerDeclSyntax.self) else {
			let diagnostic = Diagnostic(node:declaration, message: InitializerFunctionRequirementDiagnostic())
			context.diagnose(diagnostic)
			return []
		}
		guard let firstParam = funcDeclaration.signature.parameterClause.parameters.first else {
			let diagnostic = Diagnostic(node:declaration, message: InitializerFunctionRequirementDiagnostic())
			context.diagnose(diagnostic)
			return []
		}
		guard firstParam.firstName.trimmedDescription == "RAW_decode" && firstParam.type.trimmedDescription == "UnsafeRawBufferPointer" else {
			let diagnostic = Diagnostic(node:firstParam, message: InitializerFunctionRequirementDiagnostic())
			context.diagnose(diagnostic)
			return []
		}
		let paramNameToUse = firstParam.secondName?.text ?? firstParam.firstName.text

		// determine if the user has used an explicit placement of the initializer
		var assembleCodes = [SwiftSyntax.CodeBlockItemSyntax]()
		var implementedInitializer:MacroExpansionExprSyntax? = nil
		codeItemLoop: for curCodeBlockItem in declaration.body?.statements ?? CodeBlockItemListSyntax([]) {
			guard let macroExpansion = curCodeBlockItem.item.as(MacroExpansionExprSyntax.self) else {
				assembleCodes.append(curCodeBlockItem)
				continue codeItemLoop
			}
			guard macroExpansion.macroName.trimmedDescription == "RAW_staticbuff_init" else {
				assembleCodes.append(curCodeBlockItem)
				continue codeItemLoop
			}
			guard implementedInitializer == nil else {
				// throw a diagnostic error to disallow multiple uses of the macro
				let diagnostic = Diagnostic(node:macroExpansion, message: MultipleMacroUsageDiagnostic(), fixIts:[
					FixIt(message:MultipleMacroUsageDiagnostic.FixIt(), changes: [
						.replace(oldNode: Syntax(curCodeBlockItem), newNode:Syntax(DeclSyntax("")))
					])
				])
				context.diagnose(diagnostic)
				assembleCodes.append(curCodeBlockItem)
				continue codeItemLoop
			}
			let rewriter = MacroArgumentRewriter(rawStaticbuffType:firstExpression, bufferParameterName:TokenSyntax.identifier(paramNameToUse), storageKeyPath:lastName)
			let rewrittenSyntax = rewriter.rewrite(macroExpansion)
			guard let reappliedMacroExpansionSyntax = rewrittenSyntax.as(MacroExpansionExprSyntax.self) else {
				// if for some reason the rewritten syntax is not a macro expansion expression, we should not generate any code.
				let diagnostic = Diagnostic(node:rewrittenSyntax, message:InternalMacroFailure(message:"expected a macro expansion expression after rewriting, but was not able to find one."))
				context.diagnose(diagnostic)
				return []
			}
			assembleCodes.append(
				.init(item:.init(reappliedMacroExpansionSyntax))
			)
			implementedInitializer = reappliedMacroExpansionSyntax
		}
		if implementedInitializer != nil {
			return assembleCodes
		} else {
			// need to install the initializer at the end of the body since the user did not explicitly place it in the body themselves.
			assembleCodes.append(
				CodeBlockItemSyntax(
					"""
					#RAW_staticbuff_init(Self.self, RAW_decode:\(raw:paramNameToUse), storage:\\.\(raw:lastName))
					"""
				)
			)
			return assembleCodes
		}
    }
}