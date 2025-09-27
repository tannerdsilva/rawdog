// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

internal struct RAW_convertible_string_type_macro_depricated:MemberMacro {
	// the compiler error that is unconditionally thrown if this macro is invoked
	fileprivate struct ConvertToCurrentSyntax:DiagnosticMessage {
		let message:String = "this macro pattern has been deprecated. please use the new macro pattern."
		let severity:DiagnosticSeverity = .error
		let diagnosticID:MessageID = MessageID(domain:"RAW_convertible_string_type_macro_depricated", id:"stringtype_message_convert_to_current_syntax")
		fileprivate struct FixItDiagnostic:FixItMessage {
		    let message:String = "convert to the new macro usage pattern."
		    let fixItID: SwiftDiagnostics.MessageID = MessageID(domain:"RAW_convertible_string_type_macro_depricated", id:"stringtype_fixit_convert_to_current_syntax")
		}
	}

	// a bunch of syntax visitors to extract the macro configuration
	// fileprivate final class LegacyNodeExtractor:SyntaxVisitor {
	// 	let context:SwiftSyntaxMacros.MacroExpansionContext
	// 	fileprivate init(context:SwiftSyntaxMacros.MacroExpansionContext) {
	// 		self.context = context
	// 		super.init(viewMode:.sourceAccurate)
	// 	}
	// 	override func visit(_ node:AttributeListSyntax) -> SyntaxVisitorContinueKind {
	// 		return .visitChildren
	// 	}
		// finds the first identifiertypesyntax in an attribute list.
		private final class IdTypeFinderFirstName:SyntaxVisitor {
			var foundIdentifierTypeName:IdentifierTypeSyntax? = nil
			override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
				switch foundIdentifierTypeName {
				case nil:
					foundIdentifierTypeName = node
					return .skipChildren
				default:
					return .skipChildren
				}
			}
			override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
				return .skipChildren
			}
			override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
				return .skipChildren
			}
		}
		private final class IdTypeFinderFirstGenericArgument:SyntaxVisitor {
			var foundIdentifierTypeFirstGenericArgument:IdentifierTypeSyntax? = nil
			private var foundGenericArgumentList:Bool = false
			override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
				switch foundGenericArgumentList {
					case false:
					return .visitChildren
					case true:
					return .skipChildren
				}
			}
			private var foundFirstArgumentItem:Bool = false
			override func visit(_ node:GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
				switch foundFirstArgumentItem {
					case false:
					foundFirstArgumentItem = true
					let nameFinder = IdTypeFinderFirstName(viewMode:.sourceAccurate)
					nameFinder.walk(node)
					guard let foundName = nameFinder.foundIdentifierTypeName else {
						return .skipChildren
					}
					foundIdentifierTypeFirstGenericArgument = foundName
					return .visitChildren
					case true:
					return .skipChildren
				}
			}
		}

		private final class LabeledExprListFinder:SyntaxVisitor {
			private var foundLabeledExprList:Bool = false
			override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
				switch foundLabeledExprList {
					case false:
					foundLabeledExprList = true
					return .visitChildren
					case true:
					return .skipChildren
				}
			}
			private var foundFirstLabledExpr:Bool = false
			override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
				switch foundFirstLabledExpr {
					case false:
					foundFirstLabledExpr = true
					return .visitChildren
					case true:
					return .skipChildren
				}
			}
			var foundFirstDeclReferenceExpr:DeclReferenceExprSyntax? = nil
			override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
				switch foundFirstDeclReferenceExpr {
					case nil:
					foundFirstDeclReferenceExpr = node
					return .skipChildren
					default:
					return .skipChildren
				}
			}
		}
	// 	override func visit(_ node:AttributeSyntax) -> SyntaxVisitorContinueKind {
	// 		let idlister = IdTypeFinderFirstName(viewMode:.sourceAccurate)
	// 		idlister.walk(node.attributeName)
	// 		guard idlister.foundIdentifierTypeName != nil else {
	// 			return .skipChildren
	// 		}
	// 		guard idlister.foundIdentifierTypeName!.name.text == "RAW_convertible_string_type" else {
	// 			return .skipChildren
	// 		}

	// 		let genericIdlister = IdTypeFinderFirstGenericArgument(viewMode:.sourceAccurate)
	// 		genericIdlister.walk(node.attributeName)
	// 		guard genericIdlister.foundIdentifierTypeFirstGenericArgument != nil else {
	// 			return .skipChildren
	// 		}

	// 		let labeledExprListFinder = LabeledExprListFinder(viewMode:.sourceAccurate)
	// 		labeledExprListFinder.walk(node)
	// 		guard labeledExprListFinder.foundFirstDeclReferenceExpr != nil else {
	// 			return .skipChildren
	// 		}

	// 		// isolate the syntax that defines the unicode type and strip it of all trivia.
	// 		var unicodeType:DeclReferenceExprSyntax = labeledExprListFinder.foundFirstDeclReferenceExpr!
	// 		unicodeType.leadingTrivia = ""
	// 		unicodeType.trailingTrivia = ""
	// 		let unicodeTypeText = unicodeType.baseName.text
	// 		// translate the unicode type into its new syntax form
	// 		let newGenericArgumentList = GenericArgumentSyntax(argument:IdentifierTypeSyntax(name:"\(raw:unicodeTypeText)"))

	// 		// isolate the syntax that defines the backing type and strip it of all trivia.
	// 		var backingType:IdentifierTypeSyntax = genericIdlister.foundIdentifierTypeFirstGenericArgument!
	// 		backingType.leadingTrivia = ""
	// 		backingType.trailingTrivia = ""
	// 		let backingTypeText = backingType.name.text
	// 		// translate the backing type into its new syntax form
	// 		let newLabeledExprList = LabeledExprSyntax(label:"backing", colon:TokenSyntax.colonToken(), expression:ExprSyntax("\(raw:backingTypeText).self"))

	// 		// assemble the suggested syntax corrections
	// 		var modifyAttribute = node
	// 		modifyAttribute.arguments = AttributeSyntax.Arguments([newLabeledExprList])
	// 		var modifyAttributeName = IdentifierTypeSyntax(name:"RAW_convertible_string_type")
	// 		modifyAttributeName.genericArgumentClause = GenericArgumentClauseSyntax(leftAngle:TokenSyntax.leftAngleToken(), arguments:[newGenericArgumentList], rightAngle:TokenSyntax.rightAngleToken())
	// 		modifyAttribute.attributeName = TypeSyntax(modifyAttributeName)

	// 		// build the diagnostic message
	// 		let diagnostic = Diagnostic(
	// 			node:node,
	// 			message:ConvertToCurrentSyntax(),
	// 			fixIts:[
	// 				FixIt(message:ConvertToCurrentSyntax.FixItDiagnostic(), changes:[
	// 					.replace(oldNode:Syntax(node), newNode:Syntax(modifyAttribute))
	// 				])
	// 			]
	// 		)
	// 		context.diagnose(diagnostic)
	// 		return .skipChildren
	// 	}
	// }
	static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, conformingTo protocols:[TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let idlister = IdTypeFinderFirstName(viewMode:.sourceAccurate)
		idlister.walk(node.attributeName)
		guard idlister.foundIdentifierTypeName != nil else {
			return []
		}
		guard idlister.foundIdentifierTypeName!.name.text == "RAW_convertible_string_type" else {
			return []
		}

		let genericIdlister = IdTypeFinderFirstGenericArgument(viewMode:.sourceAccurate)
		genericIdlister.walk(node.attributeName)
		guard genericIdlister.foundIdentifierTypeFirstGenericArgument != nil else {
			return []
		}

		let labeledExprListFinder = LabeledExprListFinder(viewMode:.sourceAccurate)
		labeledExprListFinder.walk(node)
		guard labeledExprListFinder.foundFirstDeclReferenceExpr != nil else {
			return []
		}

		// isolate the syntax that defines the unicode type and strip it of all trivia.
		var unicodeType:DeclReferenceExprSyntax = labeledExprListFinder.foundFirstDeclReferenceExpr!
		unicodeType.leadingTrivia = ""
		unicodeType.trailingTrivia = ""
		let unicodeTypeText = unicodeType.baseName.text
		// translate the unicode type into its new syntax form
		let newGenericArgumentList = GenericArgumentSyntax(argument:GenericArgumentSyntax.Argument(IdentifierTypeSyntax(name:"\(raw:unicodeTypeText)")))

		// isolate the syntax that defines the backing type and strip it of all trivia.
		var backingType:IdentifierTypeSyntax = genericIdlister.foundIdentifierTypeFirstGenericArgument!
		backingType.leadingTrivia = ""
		backingType.trailingTrivia = ""
		let backingTypeText = backingType.name.text
		// translate the backing type into its new syntax form
		let newLabeledExprList = LabeledExprSyntax(label:"backing", colon:TokenSyntax.colonToken(), expression:ExprSyntax("\(raw:backingTypeText).self"))

		// assemble the suggested syntax corrections
		var modifyAttribute = node
		modifyAttribute.arguments = AttributeSyntax.Arguments([newLabeledExprList])
		var modifyAttributeName = IdentifierTypeSyntax(name:"RAW_convertible_string_type")
		modifyAttributeName.genericArgumentClause = GenericArgumentClauseSyntax(leftAngle:TokenSyntax.leftAngleToken(), arguments:[newGenericArgumentList], rightAngle:TokenSyntax.rightAngleToken())
		modifyAttribute.attributeName = TypeSyntax(modifyAttributeName)

		// build the diagnostic message
		let diagnostic = Diagnostic(
			node:node,
			message:ConvertToCurrentSyntax(),
			fixIts:[
				FixIt(message:ConvertToCurrentSyntax.FixItDiagnostic(), changes:[
					.replace(oldNode:Syntax(node), newNode:Syntax(modifyAttribute))
				])
			]
		)
		context.diagnose(diagnostic)
		return []
	}
}