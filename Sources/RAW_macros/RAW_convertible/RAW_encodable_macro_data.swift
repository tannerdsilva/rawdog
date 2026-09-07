// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Tools
internal struct RAW_encodable_protocol {
	internal struct MultipleMacroUsageDiagnostic:Swift.Error, DiagnosticMessage {
		internal let message:String = "RAW_staticbuff_encode macro can only be used once in the body of an initializer."
		internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"multiple_macro_usage")
		internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
	}

	internal struct CountMacro {}
	internal struct DataMacro {
		internal struct IncorrectRAWAccessibleFixedTypeDiagnostic:Swift.Error, DiagnosticMessage {
			internal let message:String = "the type specified in the RAW_encode_impl macro must be `Self.self`, where `Self` is conforming to `RAW_accessible` and `RAW_fixed`."
			internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"incorrect_raw_accessible_fixed_type")
			internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			internal struct FixItDiagnosticUseSelf:FixItMessage {
				internal let message:String = "change the type specified to `Self.self`"
				internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"incorrect_raw_accessible_fixed_type_fixit_use_self")
			}
		}

		internal final class DestinationArgumentReferenceIdentifier:SyntaxVisitor {
			internal var destVariableName:TokenSyntax? = nil
			internal var foundFuncParams:Int? = nil
			override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
				guard node.signature.parameterClause.parameters.count == 2 && foundFuncParams == nil else {
					return .skipChildren
				}
				foundFuncParams = 0
				return .visitChildren
			}
			override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
				switch foundFuncParams {
				case 0:
					foundFuncParams! += 1
					return .visitChildren
				case 1:
					guard node.firstName.trimmedDescription == "destination" else {
						return .skipChildren
					}
					if node.secondName == nil {
						destVariableName = node.firstName
					} else {
						destVariableName = node.secondName
					}
					fallthrough
				case nil:
					fallthrough
				default:
					destVariableName = nil
					foundFuncParams = nil
					return .skipChildren
				}
			}
		}
		
		fileprivate static func parseDualArguments(_ list:LabeledExprListSyntax, context:MacroExpansionContext) -> (MemberAccessExprSyntax, DeclReferenceExprSyntax)? {
			var memberAccessExpr:MemberAccessExprSyntax? = nil
			var keyPathExpr:DeclReferenceExprSyntax? = nil
			for (i, listItem) in list.enumerated() {
				switch i {
				case 0:
					guard let curMemberAccessExpr = listItem.expression.as(MemberAccessExprSyntax.self) else {
						return nil
					}
					memberAccessExpr = curMemberAccessExpr
				case 1:
					// find the path components of the key path argument.
					let allNames = RAW_macro_validators.validateRAW_keypath_argument(labeledExpression:listItem, context:context)
					
					// extract the last of the key paths.
					guard let lastComponent = allNames?.last else {
						// if we were not able to find any valid key path components in the second argument, we should not generate any code.
						fatalError()
					}
					keyPathExpr = lastComponent
				default:
					return nil
				}
			}
			guard let memberAccessExpr, let keyPathExpr else {
				return nil
			}
			return (memberAccessExpr, keyPathExpr)
		}
	}
}

// MARK: - Declaration (Freestanding)
extension RAW_encodable_protocol.DataMacro:DeclarationMacro {
	internal static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard node.arguments.count == 2 else {
			// if there are not exactly two labeled expressions in the macro invocation, we should not generate any code.
			return []
		}
		guard let (memberAccessExpr, keyPathExpr) = RAW_encodable_protocol.DataMacro.parseDualArguments(node.arguments, context:context) else {
			return []
		}

		return [
			DeclSyntax(
				"""
				@RAW_encode_impl(RAW_staticbuff:\(raw:memberAccessExpr.trimmedDescription), storage:\\.\(raw:keyPathExpr.trimmedDescription))
				borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, destination __encode_\(raw:keyPathExpr.trimmedDescription)_to_here:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
				"""
			)
		]
	}
}

// MARK: - Body (Attached)
extension RAW_encodable_protocol.DataMacro:BodyMacro {
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
		guard case let .argumentList(args) = node.arguments, args.count == 2 else {
			return []
		}
		guard let (firstArgument, _) = RAW_encodable_protocol.DataMacro.parseDualArguments(args, context:context) else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected exactly two arguments in the macro invocation, but was not able to parse them."))
			context.diagnose(diagnostic)
			return []
		}
		guard let _ = firstArgument.base?.as(DeclReferenceExprSyntax.self) else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected a valid type reference in the first argument, but was not able to find one."))
			context.diagnose(diagnostic)
			return []
		}

		var assembleCodes = [SwiftSyntax.CodeBlockItemSyntax]()
		var implementedInitializer:MacroExpansionExprSyntax? = nil
		codeItemLoop: for curCodeBlockItem in declaration.body?.statements ?? CodeBlockItemListSyntax([]) {
			guard let macroExpansion = curCodeBlockItem.item.as(MacroExpansionExprSyntax.self) else {
				assembleCodes.append(curCodeBlockItem)
				continue codeItemLoop
			}
			guard macroExpansion.macroName.trimmedDescription == "RAW_accessible_encode" else {
				assembleCodes.append(curCodeBlockItem)
				continue codeItemLoop
			}
			guard implementedInitializer == nil else {
				// throw a diagnostic error to disallow multiple uses of the macro
				let diagnostic = Diagnostic(node:curCodeBlockItem, message:RAW_encodable_protocol.MultipleMacroUsageDiagnostic())
				context.diagnose(diagnostic)
				continue codeItemLoop
			}
			assembleCodes.append(curCodeBlockItem)
			implementedInitializer = macroExpansion
		}

		let destName = RAW_encodable_protocol.DataMacro.DestinationArgumentReferenceIdentifier(viewMode:.fixedUp)
		destName.walk(declaration)

		guard let fsig = declaration.as(FunctionDeclSyntax.self)?.signature else {
			let diagnostic = Diagnostic(node:declaration, message:InternalMacroFailure(message:"expected the macro to be attached to a function declaration, but was not able to find one."))
			context.diagnose(diagnostic)
			return []
		}
		
		var destinationName:TokenSyntax? = nil
		for (i, param) in fsig.parameterClause.parameters.enumerated() {
			switch i {
			case 0:
				break;
			case 1:
				guard param.firstName.trimmedDescription == "destination" else {
					let diagnostic = Diagnostic(node:param, message:InternalMacroFailure(message:"expected the second parameter of the function to be named `destination`, but found `\(param.firstName.trimmedDescription)` instead."))
					context.diagnose(diagnostic)
					return []
				}
				destinationName = param.secondName ?? param.firstName
			default:
				let diagnostic = Diagnostic(node:param, message:InternalMacroFailure(message:"expected the function to have exactly two parameters, but found at least \(i+1)."))
				context.diagnose(diagnostic)
				return []
			}
		}

		guard let foundRefrenceName = destinationName else {
			let diagnostic = Diagnostic(node:declaration, message:InternalMacroFailure(message:"expected to find a function parameter with the second argument of the macro as its external or internal parameter name, but was not able to find one."))
			context.diagnose(diagnostic)
			return []
		}
		
		if implementedInitializer != nil {
			// the user already implemented the macro that encodes the body into the destination. there is nothing to do here.
			return assembleCodes
		} else {
			// need to install the initializer at the end of the body since the user did not explicitly place it in the body themselves.
			assembleCodes.append(
				CodeBlockItemSyntax(
					"""
					#RAW_accessible_encode(self, destination:\(raw:foundRefrenceName))
					"""
				)
			)
			return assembleCodes
		}
	}
}

extension RAW_encodable_protocol.CountMacro:DeclarationMacro {
	internal static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let (firstArgument, _) = RAW_encodable_protocol.DataMacro.parseDualArguments(node.arguments, context:context) else {
			fatalError()
		}
		
		return [
			DeclSyntax(
				"""
				@RAW_encode_count_impl(RAW_fixed:\(raw:firstArgument.base?.trimmedDescription).self)
				func RAW_encode(count: inout Int)
				"""
			)
		]
	}
}

public struct RAW_encodable_count_fixed_macro:BodyMacro, DeclarationMacro {
	public static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard node.arguments.count == 1 else {
			// if there are not exactly two labeled expressions in the macro invocation, we should not generate any code.
			fatalError()
		}
		
		return [
			DeclSyntax(
				"""
				@RAW_encode_count_impl(RAW_fixed:Self.self)
				func RAW_encode(count: inout Int)
				"""
			)
		]
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
		guard case let .argumentList(args) = node.arguments, args.count == 1 else {
			fatalError()
		}
		
		var assembleCodes = [SwiftSyntax.CodeBlockItemSyntax]()
		var implementedInitializer:MacroExpansionExprSyntax? = nil
		codeItemLoop: for curCodeBlockItem in declaration.body?.statements ?? CodeBlockItemListSyntax([]) {
			guard let macroExpansion = curCodeBlockItem.item.as(MacroExpansionExprSyntax.self) else {
				assembleCodes.append(curCodeBlockItem)
				continue codeItemLoop
			}
			guard macroExpansion.macroName.trimmedDescription == "RAW_staticbuff_encode_count" else {
				assembleCodes.append(curCodeBlockItem)
				continue codeItemLoop
			}
			guard implementedInitializer == nil else {
				// throw a diagnostic error to disallow multiple uses of the macro
				let diagnostic = Diagnostic(node:curCodeBlockItem, message: RAW_encodable_protocol.MultipleMacroUsageDiagnostic())
				context.diagnose(diagnostic)
				continue codeItemLoop
			}
			assembleCodes.append(curCodeBlockItem)
			implementedInitializer = macroExpansion
		}
		if implementedInitializer != nil {
			return assembleCodes
		} else {
			// need to install the initializer at the end of the body since the user did not explicitly place it in the body themselves.
			assembleCodes.append(
				CodeBlockItemSyntax(
					"""
					#RAW_staticbuff_encode_count(RAW_fixed:Self.self)
					"""
				)
			)
			return assembleCodes
		}
	}
}