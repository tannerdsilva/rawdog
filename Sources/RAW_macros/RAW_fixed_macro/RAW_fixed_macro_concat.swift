// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Tools
extension RAW_macros.RAW_fixed_protocol {
	internal struct ConcatMacro {
		internal final class RAW_fixed_concat_argument_validator:SyntaxVisitor {
			internal final class RAW_fixed_concat_declreferenceexpr_lister:SyntaxVisitor {
				internal var allDeclReferenceExprs:[DeclReferenceExprSyntax]? = nil
				internal override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
					guard node.baseName.trimmedDescription != "self" else {
						return .skipChildren
					}
					if allDeclReferenceExprs == nil {
						allDeclReferenceExprs = [node]
					} else {
						allDeclReferenceExprs!.append(node)
					}
					return .skipChildren
				}
			}
			internal var rootLevelMemberAccessExprs:[MemberAccessExprSyntax]? = nil
			internal var allConcatTypes:[[DeclReferenceExprSyntax]]? = nil
			internal override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
				guard let asMemberAccessExprSyntax = node.expression.as(MemberAccessExprSyntax.self), asMemberAccessExprSyntax.base != nil else {
					return .skipChildren
				}
				let declLister = RAW_fixed_concat_declreferenceexpr_lister(viewMode:.fixedUp)
				declLister.walk(asMemberAccessExprSyntax)
				guard let gotList = declLister.allDeclReferenceExprs else {
					return .skipChildren
				}
				if allConcatTypes == nil {
					allConcatTypes = [gotList]
					rootLevelMemberAccessExprs = [asMemberAccessExprSyntax]
				} else {
					allConcatTypes!.append(gotList)
					rootLevelMemberAccessExprs!.append(asMemberAccessExprSyntax)
				}
				return .skipChildren
			}
		}
		internal static func validateRAW_fixed_concat_arguments<T>(labeledExpression:LabeledExprListSyntax, context:SwiftSyntaxMacros.MacroExpansionContext, returning:T.Type = Optional<[[DeclReferenceExprSyntax]]>.self) -> [[DeclReferenceExprSyntax]]? {
			let concatTypesValidator = RAW_fixed_concat_argument_validator(viewMode:.fixedUp)
			concatTypesValidator.walk(labeledExpression)
			return concatTypesValidator.allConcatTypes
		}
		internal static func validateRAW_fixed_concat_arguments(labeledExpression:LabeledExprListSyntax, context:SwiftSyntaxMacros.MacroExpansionContext, returning:[MemberAccessExprSyntax].Type) -> [MemberAccessExprSyntax]? {
			let concatTypesValidator = RAW_fixed_concat_argument_validator(viewMode:.fixedUp)
			concatTypesValidator.walk(labeledExpression)
			return concatTypesValidator.rootLevelMemberAccessExprs
		}

		internal struct MismatchedConcatTypes:Swift.Error, SwiftDiagnostics.DiagnosticMessage {
			internal var message:String { "the concat types argument in the #RAW_fixed_type macro does not match the concat types argument in this macro. expected \(expectedConcatTypes), found \(foundConcatTypes)." }
			internal let diagnosticID: SwiftDiagnostics.MessageID = SwiftDiagnostics.MessageID(domain:"\(String(describing: RAW_macros.RAW_fixed_protocol.ConcatMacro.self))", id: "\(String(describing: Self.self))")
			internal let severity: SwiftDiagnostics.DiagnosticSeverity = .error
			internal let expectedConcatTypes:[String]
			internal let foundConcatTypes:[String]
		}
		internal struct UnconfirmedConcatTypes:Swift.Error, SwiftDiagnostics.DiagnosticMessage {
			internal var message:String { "the concat types argument in the #RAW_fixed_type macro could not be confirmed to match the concat types argument in this macro. expected \(expectedConcatTypes). implement the conformance of `RAW_fixed` on this member to resolve this error." }
			internal var diagnosticID: SwiftDiagnostics.MessageID = SwiftDiagnostics.MessageID(domain:"\(String(describing: RAW_macros.RAW_fixed_protocol.ConcatMacro.self))", id: "\(String(describing: Self.self))")
			internal let severity: SwiftDiagnostics.DiagnosticSeverity = .error
			internal let expectedConcatTypes:[String]
		}
	}
}

// MARK: - Declaration (Freestanding)
extension RAW_macros.RAW_fixed_protocol.ConcatMacro:DeclarationMacro {
	internal static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let numberOfTypes = validateRAW_fixed_concat_arguments(labeledExpression:node.arguments, context:context) ?? []
		guard numberOfTypes.count >= 1 else {
			// if there are not any valid member access expressions in the argument, we should not generate any code.
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected at least one concat type argument in #RAW_fixed_type(concat:) macro.")); context.diagnose(diagnostic); return []
		}
		var buildTupleString = "("
		for (i, nType) in numberOfTypes.enumerated() {
			if i != 0 {
				buildTupleString += ", "
			}
			buildTupleString += (nType.compactMap({$0.trimmedDescription}).joined(separator: ".") + ".RAW_fixed_type")
		}
		buildTupleString += ")"
		return [
			DeclSyntax("public typealias RAW_fixed_type = \(raw:buildTupleString)")
		]
	}
}

// MARK: - Extension (Attached)
extension RAW_macros.RAW_fixed_protocol.ConcatMacro:ExtensionMacro {
	internal static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard case let .argumentList(args) = node.arguments else {
			// if there are not exactly one argument in the macro, we should not generate any code.
			return []
		}

		var returnValues = [SwiftSyntax.ExtensionDeclSyntax]()
		guard let concatTypes = validateRAW_fixed_concat_arguments(labeledExpression:args, context:context, returning:[MemberAccessExprSyntax].self) else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"could not validate concat type arguments in @RAW_fixed(concat:) macro.")); context.diagnose(diagnostic); return []
		}
		var buildAllConcatTypesString = ""
		for (i, concatType) in concatTypes.enumerated() {
			if i != 0 {
				buildAllConcatTypesString += ", "
			}
			buildAllConcatTypesString += concatType.trimmedDescription
		}
		var implemented:Set<String> = []

		// if there are no protocols in the extension declaration, we should not generate any code.
		seekLoop: for proto in protocols {
			defer {
				implemented.insert(proto.trimmedDescription)
			}
			switch proto.trimmedDescription {
				case "RAW_fixed":
						returnValues += [
							try! ExtensionDeclSyntax(
								"""
								extension \(raw:type.trimmedDescription):\(raw:proto.trimmedDescription) {
									#RAW_fixed_type(concat:\(raw:buildAllConcatTypesString))
								}
								"""
							)
						]
				default:
					// if the macro is attached to an extension declaration that does not conform to "RAW_fixed", we should not generate any code.
					continue seekLoop
			}
		}

		if implemented.contains("RAW_fixed") == false {
			// indicates that the user already implemented this macro themselves, so now the goal is to validate that the inner usage of the #RAW_fixed_type macro matches the expected format as configured by this macro.

			// scan the body to determine if the #RAW_fixed_type macro is being used, if it is not being used, then we should not generate any code.
			let macroSearcher = Freestanding_macro_searcher(expectedMacroName:"RAW_fixed_type", viewMode:.fixedUp)
			macroSearcher.walk(declaration)
			if macroSearcher.foundMacro != nil {
				// audit the usage of the inner freestanding expression macro to ensure it matches the expected format as configured by this macro.
				let foundMacroArgument = macroSearcher.foundMacro!.first!
				let potentiallyIncorrectByteCount = validateRAW_fixed_concat_arguments(labeledExpression:macroSearcher.foundMacro!, context:context, returning:[MemberAccessExprSyntax].self)
				guard potentiallyIncorrectByteCount?.compactMap({ $0.trimmedDescription }) == concatTypes.compactMap({ $0.trimmedDescription }) else {
					let diag = Diagnostic(node:foundMacroArgument.expression, message:MismatchedConcatTypes(expectedConcatTypes:concatTypes.map({ $0.trimmedDescription }), foundConcatTypes:potentiallyIncorrectByteCount?.compactMap({ $0.trimmedDescription }) ?? []))
					context.diagnose(diag)
					return []
				}
				// no need to implement because the user has expressed their own macro here. the two macros agree in configuration.
			} else {
				let diag = Diagnostic(node:args, message:UnconfirmedConcatTypes(expectedConcatTypes:concatTypes.map({ $0.trimmedDescription })))
				context.diagnose(diag)
				return []
			}
		}
		return returnValues
	}
}
