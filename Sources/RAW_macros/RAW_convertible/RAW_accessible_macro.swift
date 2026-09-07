// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

internal struct RAW_accessible_protocol {
	internal struct ImmutableMacro {}
	internal struct MutableMacro {}
}

// MARK: - Immutable Declaration (Freestanding)
extension RAW_accessible_protocol.ImmutableMacro:DeclarationMacro {
	// freestanding macro declaration expansion
	public static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard node.arguments.count == 2 else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"found \(node.arguments.count) arguments in #RAW_accessible_immutable macro invocation, but expected 2."))
			context.diagnose(diagnostic)
			return []
		}
		var firstExpression:MemberAccessExprSyntax? = nil
		var storageName:DeclReferenceExprSyntax? = nil
		argLoop: for (i, arg) in node.arguments.enumerated() {
			switch i {
				case 0:
					firstExpression = arg.expression.as(MemberAccessExprSyntax.self)
					continue argLoop
				case 1:					
					// extract the last of the key paths.
					guard let lastComponent = RAW_macro_validators.validateRAW_keypath_argument(labeledExpression:arg, context:context)?.last else {
						// if we were not able to find any valid key path components in the second argument, we should not generate any code.
						let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument contents in #RAW_accessible_immutable macro invocation."))
						context.diagnose(diagnostic)
						return []
					}
					
					storageName = lastComponent
					continue argLoop
				default:
					let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"found more arguments than expected in #RAW_accessible_immutable macro invocation. expected 2, found at least \(i+1)."))
					context.diagnose(diagnostic)
			}
		}

		guard let firstExpression = firstExpression, let storageName else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unable to find first expression of the key path expression list in #RAW_accessible_immutable macro invocation."))
			context.diagnose(diagnostic)
			return []
		}

		guard let feBase = firstExpression.base else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unable to find a base for the first expression in #RAW_accessible_immutable macro invocation."))
			context.diagnose(diagnostic)
			return []
		}

		// validate that Self.self is the base of the member access expression in the first argument.
		if feBase.trimmedDescription != "Self" {
			let diagnostic = Diagnostic(node:firstExpression, message:TypeMustBeSelfFailure(found:firstExpression.trimmedDescription), fixIts:[
				FixIt(message:TypeMustBeSelfFailure.FixIt(), changes:[
					.replace(oldNode: Syntax(feBase), newNode: Syntax(IdentifierTypeSyntax(name:TokenSyntax.identifier("Self"))))
				])
			])
			context.diagnose(diagnostic)
		}

		return [
			DeclSyntax(
				"""
				@RAW_access_immutable_impl(RAW_staticbuff:Self.self, storage:\\.\(raw:storageName.trimmedDescription))
				borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ __body_to_pass_\(raw:storageName.trimmedDescription)_argument:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error
				"""
			)
		]
	}
}

internal final class MacroArgumentRewriter:SwiftSyntax.SyntaxRewriter {
	let storageKeyPath:DeclReferenceExprSyntax
	let bufferParameterName:TokenSyntax
	let bodyReturnType:GenericParameterSyntax
	let bodyThrowsType:GenericParameterSyntax
	init(storageKeyPath:DeclReferenceExprSyntax, bodyReturnType:GenericParameterSyntax, bodyThrowsType:GenericParameterSyntax, bufferParameterName:TokenSyntax) {
		self.storageKeyPath = storageKeyPath
		self.bufferParameterName = bufferParameterName
		self.bodyReturnType = bodyReturnType
		self.bodyThrowsType = bodyThrowsType
		super.init(viewMode:.fixedUp)
	}
	
	override func visit(_ _:LabeledExprListSyntax) -> LabeledExprListSyntax {
		var newList = [LabeledExprSyntax]()
		
		newList.append(LabeledExprSyntax(expression:ExprSyntax(stringLiteral: "self"), trailingComma:TokenSyntax.commaToken()))
		
		let keyPathLabeledExpr = LabeledExprSyntax(label:TokenSyntax.identifier("storage"), colon:.colonToken(), expression:KeyPathExprSyntax(backslash:.backslashToken(), components:KeyPathComponentListSyntax([KeyPathComponentSyntax(period:.periodToken(), component:.property(KeyPathPropertyComponentSyntax(declName:storageKeyPath)))])),
			trailingComma:TokenSyntax.commaToken())
		newList.append(keyPathLabeledExpr)
		
		newList.append(
			LabeledExprSyntax(
				label: TokenSyntax.identifier("bodyReturnType"),
				colon: .colonToken(),
				expression: ExprSyntax(stringLiteral: "\(bodyReturnType.trimmedDescription).self"),
				trailingComma:TokenSyntax.commaToken()
			)
		)

		newList.append(
			LabeledExprSyntax(
				label: TokenSyntax.identifier("bodyThrowsType"),
				colon: .colonToken(),
				expression: ExprSyntax(stringLiteral: "\(bodyThrowsType.trimmedDescription).self"),
				trailingComma:TokenSyntax.commaToken()
			)
		)
		
		newList.append(
			LabeledExprSyntax(
				label:TokenSyntax.identifier("body"),
				colon:.colonToken(),
				expression:DeclReferenceExprSyntax(baseName:self.bufferParameterName)
			)
		)
		
		return LabeledExprListSyntax(newList)
	}
}

// MARK: - Immutable Body
extension RAW_accessible_protocol.ImmutableMacro:BodyMacro {
	internal struct MultipleMacroUsageDiagnostic:Swift.Error, DiagnosticMessage {
		internal let message:String = "RAW_staticbuff_access macro can only be used once in the body of the RAW_access_immutable function."
		internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"multiple_macro_usage_diag")
		internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		internal struct FixIt:FixItMessage {
			internal let message:String = "remove the duplicate usage of the #RAW_staticbuff_access macro."
			internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"multiple_macro_usage_fixit")
		}
	}

	internal struct InvalidFunctionDiagnostic:Swift.Error, DiagnosticMessage {
		internal let message:String = "RAW_staticbuff_access macro can only be attached to a proper RAW_access_immutable function."
		internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"invalid_function_diag")
		internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		internal struct FixIt:FixItMessage {
			internal let message:String = "fix the RAW_access_immutable function definition."
			internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"invalid_function_fixit")
		}
	}
	
	// body macro expansion
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
		guard case let .argumentList(args) = node.arguments, args.count == 2 else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument contents."))
			context.diagnose(diagnostic)
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
		guard let funcDeclSyntax = declaration.as(FunctionDeclSyntax.self) else {
			let diagnostic = Diagnostic(node:declaration, message:InternalMacroFailure(message:"the declaration attached to the #RAW_access_immutable macro is not a function declaration."))
			context.diagnose(diagnostic)
			return []
		}
		guard funcDeclSyntax.name.trimmedDescription == "RAW_access_immutable" else {
			let diagnostic = Diagnostic(node:declaration, message:InternalMacroFailure(message:"the declaration attached to the #RAW_access_immutable macro does not have the expected function name of `RAW_access_immutable`. found `\(funcDeclSyntax.name.trimmedDescription)`."))
			context.diagnose(diagnostic)
			return []
		}
		
		let replacementFixIt = SwiftDiagnostics.FixIt(
			message: InvalidFunctionDiagnostic.FixIt(),
			changes: [
				.replace(oldNode: Syntax(funcDeclSyntax), newNode: Syntax(CodeBlockItemSyntax(leadingTrivia: funcDeclSyntax.leadingTrivia, item:
				CodeBlockItemSyntax("""
				@RAW_access_immutable_impl(RAW_staticbuff: Self.self, storage: \\.\(raw:lastName.trimmedDescription))
				borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error \(raw: funcDeclSyntax.body?.description ?? "")
				""").item)))
			]
		)

		let diagnostic = Diagnostic(
			node: funcDeclSyntax,
			message: InvalidFunctionDiagnostic(),
			fixIts: [replacementFixIt]
		)
		
		guard let genericParams = funcDeclSyntax.genericParameterClause, genericParams.parameters.count == 2 else {
			 context.diagnose(diagnostic)
			return []
		}
		guard let genericParameterClause = funcDeclSyntax.genericParameterClause, genericParameterClause.parameters.count == 2 else {
			 context.diagnose(diagnostic)
			return []
		}
		var buildAllGParams = [String:GenericParameterSyntax]()
		for param in genericParameterClause.parameters {
			buildAllGParams[param.name.trimmedDescription] = param
		}
		guard funcDeclSyntax.signature.parameterClause.parameters.count == 2 else {
			 context.diagnose(diagnostic)
			return []
		}
		var officialReturnType:GenericParameterSyntax? = nil
		var officialThrowingType:GenericParameterSyntax? = nil
		for (i, param) in funcDeclSyntax.signature.parameterClause.parameters.enumerated() {
			switch i {
				case 0:
					guard param.firstName.trimmedDescription == "_" else {
						 context.diagnose(diagnostic)
						return []
					}
					continue
				case 1: 
					guard let ftypeSyntax = param.type.as(FunctionTypeSyntax.self) else {
						 context.diagnose(diagnostic)
						return []
					}

					// find the return type first
					guard let returnClause = ftypeSyntax.returnClause.type.as(IdentifierTypeSyntax.self) else {
						context.diagnose(diagnostic)
						return []
					}
					guard let identifiedReturnType = buildAllGParams[returnClause.name.trimmedDescription] else {
						context.diagnose(diagnostic)
						return []
					}
					officialReturnType = GenericParameterSyntax(name:.identifier(identifiedReturnType.name.trimmedDescription))

					// find the throwing error type if it exists
					guard let throwsOrRethrows = ftypeSyntax.effectSpecifiers?.throwsClause else {
						// if there is no throws or rethrows clause, then we can assume that the function does not throw and we can set the identifiedThrowingErrorType to nil.
						break
					}
					guard let throwingErrorType = throwsOrRethrows.type?.as(IdentifierTypeSyntax.self) else {
						context.diagnose(diagnostic)
						return []
					}
					guard let identifiedThrowingType = buildAllGParams[throwingErrorType.name.trimmedDescription] else {
						context.diagnose(diagnostic)
						return []
					}
					officialThrowingType = GenericParameterSyntax(name:.identifier(identifiedThrowingType.name.trimmedDescription))
					continue
				default:
					context.diagnose(diagnostic)
			}
		}

		var bodyVarName:TokenSyntax? = nil
		seekLoop: for (i, fparam) in funcDeclSyntax.signature.parameterClause.parameters.enumerated() {
			switch i {
				// skipping case 0 because we dont care. we're only here to parse the throwing and return types from the second argument type.
				case 1:
					guard fparam.firstName.trimmedDescription == "_" else {
						context.diagnose(diagnostic)
						return []
					}
					guard let requiredSecondName = fparam.secondName else {
						context.diagnose(diagnostic)
						return []
					}
					bodyVarName = requiredSecondName
					break seekLoop;
				default:
					continue seekLoop;
			}
		}
		guard let bodyName = bodyVarName, let officialReturnType = officialReturnType, let officialThrowingType = officialThrowingType else {
			context.diagnose(diagnostic)
			return []
		}
		
		func firstMacroExpansion(in node: Syntax) -> MacroExpansionExprSyntax? {
			if let macro = node.as(MacroExpansionExprSyntax.self) {
				return macro
			}
			for element in node.children(viewMode: .sourceAccurate) {
				if let found = firstMacroExpansion(in: element._syntaxNode) {
					return found
				}
			}
			return nil
		}

		// determine if the user has used an explicit placement of the initializer
		var assembleCodes = [SwiftSyntax.CodeBlockItemSyntax]()
		var implementedFunction:MacroExpansionExprSyntax? = nil
		if let hasBody = declaration.body {
			codeItemLoop: for curCodeBlockItem in hasBody.statements {
				guard let macroExpansion = firstMacroExpansion(in: curCodeBlockItem.item._syntaxNode) else {
					assembleCodes.append(curCodeBlockItem)
					continue codeItemLoop
				}
				guard macroExpansion.macroName.trimmedDescription == "RAW_staticbuff_access" else {
					assembleCodes.append(curCodeBlockItem)
					continue codeItemLoop
				}

				guard implementedFunction == nil else {
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
				
				let rewriter = MacroArgumentRewriter(storageKeyPath: lastName, bodyReturnType: officialReturnType, bodyThrowsType: officialThrowingType, bufferParameterName: bodyName)
				let rewrittenSyntax = rewriter.rewrite(curCodeBlockItem)

				assembleCodes.append(
					CodeBlockItemSyntax(rewrittenSyntax)!
				)
				implementedFunction = macroExpansion
			}
		}
		
		if implementedFunction != nil {
			return assembleCodes
		} else {
			assembleCodes.append(
				CodeBlockItemSyntax(
					"""
					return #RAW_staticbuff_access(self, storage:\\.\(raw:lastName.trimmedDescription), bodyReturnType:\(raw:officialReturnType.trimmedDescription).self, bodyThrowsType: \(raw:officialThrowingType.trimmedDescription).self, body:\(raw: bodyName.trimmedDescription))
					"""
				)
			)
			return assembleCodes
		}
    }
}

// MARK: - Mutable Declaration (Freestanding)
extension RAW_accessible_protocol.MutableMacro:DeclarationMacro {
	// freestanding macro declaration expansion
	public static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard node.arguments.count == 2 else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"found \(node.arguments.count) arguments in #RAW_accessible_mutable macro invocation, but expected 2."))
			context.diagnose(diagnostic)
			return []
		}
		var firstExpression:MemberAccessExprSyntax? = nil
		var storageName:DeclReferenceExprSyntax? = nil
		argLoop: for (i, arg) in node.arguments.enumerated() {
			switch i {
				case 0:
					firstExpression = arg.expression.as(MemberAccessExprSyntax.self)
					continue argLoop
				case 1:
					// extract the last of the key paths.
					guard let lastComponent = RAW_macro_validators.validateRAW_keypath_argument(labeledExpression:arg, context:context)?.last else {
						// if we were not able to find any valid key path components in the second argument, we should not generate any code.
						let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument contents in #RAW_accessible_mutable macro invocation."))
						context.diagnose(diagnostic)
						return []
					}
					
					storageName = lastComponent
					continue argLoop
				default:
					let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"found more arguments than expected in #RAW_accessible_mutable macro invocation. expected 2, found at least \(i+1)."))
					context.diagnose(diagnostic)
			}
		}

		guard let firstExpression = firstExpression, let storageName else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unable to find first expression of the key path expression list in #RAW_accessible_mutable macro invocation."))
			context.diagnose(diagnostic)
			return []
		}

		guard let feBase = firstExpression.base else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unable to find a base for the first expression in #RAW_accessible_mutable macro invocation."))
			context.diagnose(diagnostic)
			return []
		}

		// validate that Self.self is the base of the member access expression in the first argument.
		if feBase.trimmedDescription != "Self" {
			let diagnostic = Diagnostic(node:firstExpression, message:TypeMustBeSelfFailure(found:firstExpression.trimmedDescription), fixIts:[
				FixIt(message:TypeMustBeSelfFailure.FixIt(), changes:[
					.replace(oldNode: Syntax(feBase), newNode: Syntax(IdentifierTypeSyntax(name:TokenSyntax.identifier("Self"))))
				])
			])
			context.diagnose(diagnostic)
		}

		return [
			DeclSyntax(
				"""
				@RAW_access_mutable_impl(RAW_staticbuff:Self.self, storage:\\.\(raw:storageName.trimmedDescription))
				mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ __body_to_pass_\(raw:storageName.trimmedDescription)_argument:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error
				"""
			)
		]
	}
}

// MARK: - Immutable Body
extension RAW_accessible_protocol.MutableMacro:BodyMacro {
	internal struct MultipleMacroUsageDiagnostic:Swift.Error, DiagnosticMessage {
		internal let message:String = "RAW_staticbuff_access_mutating macro can only be used once in the body of the RAW_access_mutable function."
		internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"multiple_macro_usage_diag")
		internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		internal struct FixIt:FixItMessage {
			internal let message:String = "remove the duplicate usage of the #RAW_staticbuff_access macro."
			internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"multiple_macro_usage_fixit")
		}
	}
	
	internal struct InvalidFunctionDiagnostic:Swift.Error, DiagnosticMessage {
		internal let message:String = "RAW_staticbuff_access_mutating macro can only be attached to a proper RAW_access_mutable function."
		internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"invalid_function_diag")
		internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		internal struct FixIt:FixItMessage {
			internal let message:String = "fix the RAW_access_mutable function definition."
			internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_accessible_protocol", id:"invalid_function_fixit")
		}
	}
	
	// body macro expansion
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
		guard case let .argumentList(args) = node.arguments, args.count == 2 else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unexpected argument contents."))
			context.diagnose(diagnostic)
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
		guard let funcDeclSyntax = declaration.as(FunctionDeclSyntax.self) else {
			let diagnostic = Diagnostic(node:declaration, message:InternalMacroFailure(message:"the declaration attached to the #RAW_access_mutable macro is not a function declaration."))
			context.diagnose(diagnostic)
			return []
		}
		guard funcDeclSyntax.name.trimmedDescription == "RAW_access_mutable" else {
			let diagnostic = Diagnostic(node:declaration, message:InternalMacroFailure(message:"the declaration attached to the #RAW_access_mutable macro does not have the expected function name of `RAW_access_mutable`. found `\(funcDeclSyntax.name.trimmedDescription)`."))
			context.diagnose(diagnostic)
			return []
		}
		
		let replacementFixIt = SwiftDiagnostics.FixIt(
			message: InvalidFunctionDiagnostic.FixIt(),
			changes: [
				.replace(oldNode: Syntax(funcDeclSyntax), newNode: Syntax(CodeBlockItemSyntax(leadingTrivia: funcDeclSyntax.leadingTrivia, item:
				CodeBlockItemSyntax("""
				@RAW_access_mutable_impl(RAW_staticbuff: Self.self, storage: \\.\(raw:lastName.trimmedDescription))
				mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ __body_to_pass__bytes_argument: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error \(raw: funcDeclSyntax.body?.description ?? "")
				""").item)))
			]
		)

		let diagnostic = Diagnostic(
			node: funcDeclSyntax,
			message: InvalidFunctionDiagnostic(),
			fixIts: [replacementFixIt]
		)
		
		guard let genericParams = funcDeclSyntax.genericParameterClause, genericParams.parameters.count == 2 else {
			 context.diagnose(diagnostic)
			return []
		}
		guard let genericParameterClause = funcDeclSyntax.genericParameterClause, genericParameterClause.parameters.count == 2 else {
			 context.diagnose(diagnostic)
			return []
		}
		var buildAllGParams = [String:GenericParameterSyntax]()
		for param in genericParameterClause.parameters {
			buildAllGParams[param.name.trimmedDescription] = param
		}
		guard funcDeclSyntax.signature.parameterClause.parameters.count == 2 else {
			 context.diagnose(diagnostic)
			return []
		}
		var officialReturnType:GenericParameterSyntax? = nil
		var officialThrowingType:GenericParameterSyntax? = nil
		for (i, param) in funcDeclSyntax.signature.parameterClause.parameters.enumerated() {
			switch i {
				case 0:
					guard param.firstName.trimmedDescription == "_" else {
						 context.diagnose(diagnostic)
						return []
					}
					continue
				case 1:
					guard let ftypeSyntax = param.type.as(FunctionTypeSyntax.self) else {
						 context.diagnose(diagnostic)
						return []
					}

					// find the return type first
					guard let returnClause = ftypeSyntax.returnClause.type.as(IdentifierTypeSyntax.self) else {
						context.diagnose(diagnostic)
						return []
					}
					guard let identifiedReturnType = buildAllGParams[returnClause.name.trimmedDescription] else {
						context.diagnose(diagnostic)
						return []
					}
					officialReturnType = GenericParameterSyntax(name:.identifier(identifiedReturnType.name.trimmedDescription))

					// find the throwing error type if it exists
					guard let throwsOrRethrows = ftypeSyntax.effectSpecifiers?.throwsClause else {
						// if there is no throws or rethrows clause, then we can assume that the function does not throw and we can set the identifiedThrowingErrorType to nil.
						break
					}
					guard let throwingErrorType = throwsOrRethrows.type?.as(IdentifierTypeSyntax.self) else {
						context.diagnose(diagnostic)
						return []
					}
					guard let identifiedThrowingType = buildAllGParams[throwingErrorType.name.trimmedDescription] else {
						context.diagnose(diagnostic)
						return []
					}
					officialThrowingType = GenericParameterSyntax(name:.identifier(identifiedThrowingType.name.trimmedDescription))
					continue
				default:
					context.diagnose(diagnostic)
			}
		}

		var bodyVarName:TokenSyntax? = nil
		seekLoop: for (i, fparam) in funcDeclSyntax.signature.parameterClause.parameters.enumerated() {
			switch i {
				// skipping case 0 because we dont care. we're only here to parse the throwing and return types from the second argument type.
				case 1:
					guard fparam.firstName.trimmedDescription == "_" else {
						context.diagnose(diagnostic)
						return []
					}
					guard let requiredSecondName = fparam.secondName else {
						context.diagnose(diagnostic)
						return []
					}
					bodyVarName = requiredSecondName
					break seekLoop;
				default:
					continue seekLoop;
			}
		}
		guard let bodyName = bodyVarName, let officialReturnType = officialReturnType, let officialThrowingType = officialThrowingType else {
			context.diagnose(diagnostic)
			return []
		}
		
		func firstMacroExpansion(in node: Syntax) -> MacroExpansionExprSyntax? {
			if let macro = node.as(MacroExpansionExprSyntax.self) {
				return macro
			}
			for element in node.children(viewMode: .sourceAccurate) {
				if let found = firstMacroExpansion(in: element._syntaxNode) {
					return found
				}
			}
			return nil
		}

		// determine if the user has used an explicit placement of the initializer
		var assembleCodes = [SwiftSyntax.CodeBlockItemSyntax]()
		var implementedFunction:MacroExpansionExprSyntax? = nil
		if let hasBody = declaration.body {
			codeItemLoop: for curCodeBlockItem in hasBody.statements {
				guard let macroExpansion = firstMacroExpansion(in: curCodeBlockItem.item._syntaxNode) else {
					assembleCodes.append(curCodeBlockItem)
					continue codeItemLoop
				}
				guard macroExpansion.macroName.trimmedDescription == "RAW_staticbuff_access_mutating" else {
					assembleCodes.append(curCodeBlockItem)
					continue codeItemLoop
				}

				guard implementedFunction == nil else {
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
				
				let rewriter = MacroArgumentRewriter(storageKeyPath: lastName, bodyReturnType: officialReturnType, bodyThrowsType: officialThrowingType, bufferParameterName: bodyName)
				let rewrittenSyntax = rewriter.rewrite(curCodeBlockItem)

				assembleCodes.append(
					CodeBlockItemSyntax(rewrittenSyntax)!
				)
				implementedFunction = macroExpansion
			}
		}
		
		if implementedFunction != nil {
			return assembleCodes
		} else {
			assembleCodes.append(
				CodeBlockItemSyntax(
					"""
					return #RAW_staticbuff_access_mutating(self, storage:\\.\(raw:lastName.trimmedDescription), bodyReturnType:\(raw:officialReturnType.trimmedDescription).self, bodyThrowsType: \(raw:officialThrowingType.trimmedDescription).self, body:\(raw: bodyName.trimmedDescription))
					"""
				)
			)
			return assembleCodes
		}
	}
}
