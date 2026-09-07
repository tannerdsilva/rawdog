// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

internal struct RAW_fixed_protocol {
	/// designed to be used on a single `LabeledExprSyntax` to validate that the argument type is a valid base10 integer literal expression.
	internal final class RAW_fixed_bytes_argument_validator:SyntaxVisitor {
		internal struct InvalidPrefixOperator:DiagnosticMessage {
			internal var message:String { "invalid prefix operator '\(prefixOperator.operator.text)' found in bytes argument expression. only positive integer literals are allowed." }
			internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.self))", id:"\(String(describing:InvalidPrefixOperator.self))")
			internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			private let prefixOperator:PrefixOperatorExprSyntax
			internal init(prefixOperator:PrefixOperatorExprSyntax) {
				self.prefixOperator = prefixOperator
			}
			internal struct FixItDiagnostic:FixItMessage {
				internal let message:String = "remove the invalid prefix operator from this expression."
				internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.self))", id:"\(String(describing:FixItDiagnostic.self))")
			}
		}

		internal struct FloatLiteralExpressionFound:DiagnosticMessage {
			internal var message:String { "float literal expressions are not allowed. only integer literals can be used to express the size of a `RAW_fixed_type`." }
			internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.self))", id:"\(String(describing:FloatLiteralExpressionFound.self))")
			internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		}

		internal struct InvalidIntegerLiteralFormat:DiagnosticMessage {
			internal var message:String { "invalid integer literal format found in bytes argument expression. only valid base10 integer literals are allowed." }
			internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.self))", id:"\(String(describing:InvalidIntegerLiteralFormat.self))")
			internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		}

		internal struct InternalError:DiagnosticMessage {
			internal var message:String { "an internal error was encountered while validating the bytes argument expression. this is likely a bug in the macro implementation." }
			internal let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"\(String(describing:RAW_macros.RAW_fixed_protocol.self))", id:"\(String(describing:InternalError.self))")
			internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		}

		private let context:SwiftSyntaxMacros.MacroExpansionContext
		private var stage:Int = 0

		internal var foundLabeledExpressionSyntaxNode:ExprSyntaxProtocol? = nil
		internal var numberOfBytes:Int? = nil

		internal init(context:SwiftSyntaxMacros.MacroExpansionContext) {
			self.context = context
			super.init(viewMode:.fixedUp)
		}
		
		override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
			switch stage {
				case 0:
					stage += 1 // stage 0 to 1
					foundLabeledExpressionSyntaxNode = node.expression
					let integerLiteralValueValidator = IntegerLiteralValueValidator(viewMode:.fixedUp)
					integerLiteralValueValidator.walk(node.expression)
					numberOfBytes = integerLiteralValueValidator.numberOfBytes
					guard numberOfBytes != nil else {
						switch integerLiteralValueValidator.invalidPrefixOperator {
							case .floatLiteralExpressionFound(let floatLiteralExpr):
								let diag = Diagnostic(node:floatLiteralExpr, message:FloatLiteralExpressionFound())
								context.diagnose(diag)
							case .invalidPrefixOperatorFound(let prefixOperatorExpr):
								let diag = Diagnostic(node:prefixOperatorExpr, message:InvalidPrefixOperator(prefixOperator:prefixOperatorExpr))
								context.diagnose(diag)
							case .invalidIntegerLiteralFormatFound(let integerLiteralExpr):
								let diag = Diagnostic(node:integerLiteralExpr, message:InvalidIntegerLiteralFormat())
								context.diagnose(diag)
							default:
								let diag = Diagnostic(node:node.expression, message:InternalError())
								context.diagnose(diag)
						}
						return .skipChildren
					}
					return .visitChildren
				default:
					stage = -1
					// if we have already found the "bytes" labeled expression, we should not find any more.
					return .skipChildren
			}
		}
	}
	
	internal final class IntegerLiteralValueValidator:SyntaxVisitor {
		internal enum ValidationProblem:Swift.Error {
			case floatLiteralExpressionFound(FloatLiteralExprSyntax)
			case invalidPrefixOperatorFound(PrefixOperatorExprSyntax)
			case invalidIntegerLiteralFormatFound(IntegerLiteralExprSyntax)
		}

		/// assigned the value of the integer literal expression if it is valid, otherwise it remains nil.
		internal var numberOfBytes:Int? = nil

		/// applied when a non-positive prefix operator is found. this is used later to show a diagnostic message in the event that the we find an integer literal expression over a float literal expression.
		internal var invalidPrefixOperator:ValidationProblem? = nil

		internal override func visit(_ node:PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
			guard invalidPrefixOperator == nil else {
				// if we have already found an invalid prefix operator, we should not find any more prefix operators.
				return .skipChildren
			}

			if node.operator.text == "+" {
				// do not modify stage as positive prefix is allowed, even if it is redundant and ignored.
				return .visitChildren
			} else {
				// cannot have a negative value or any other kind of prefix operator.
				invalidPrefixOperator = .invalidPrefixOperatorFound(node)
				return .skipChildren
			}
		}
		internal override func visit(_ node:FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
			guard invalidPrefixOperator == nil else {
				// if we have already found an invalid prefix operator, we should not find any more float literal expressions.
				return .skipChildren
			}
			invalidPrefixOperator = .floatLiteralExpressionFound(node)
			return .skipChildren
		}
		internal override func visit(_ node:IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
			guard invalidPrefixOperator == nil else {
				// if we have found a prefix operator that is not positive, then the integer literal expression is invalid.
				return .skipChildren
			}
			let text = node.literal.text
			// validate: must be "0" or start with 1-9, followed by digits/underscores
			guard text.allSatisfy({ $0.isNumber || $0 == "_" }) else {
				invalidPrefixOperator = .invalidIntegerLiteralFormatFound(node)
				return .skipChildren
			}
			guard text.first != "0" || text.count == 1 else {
				invalidPrefixOperator = .invalidIntegerLiteralFormatFound(node)
				return .skipChildren
			}
			var literalText = text
			literalText.removeAll(where: { $0 == "_" })
			numberOfBytes = Int(literalText)
			guard numberOfBytes != nil && numberOfBytes! >= 0 else {
				invalidPrefixOperator = .invalidIntegerLiteralFormatFound(node)
				return .skipChildren
			}
			return .skipChildren
		}
	}

	/// designed to be used on a single `LabeledExprSyntax` to validate that the argument type is a valid base10 integer literal expression.
	internal final class RAW_macros_keypath_argument_validator:SyntaxVisitor {
		fileprivate final class ReferenceCollector:SyntaxVisitor {
			fileprivate var allDecls:[DeclReferenceExprSyntax] = []
			fileprivate override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
				allDecls.append(node)
				return .visitChildren
			}
		}
		internal var keyPathComponents:[DeclReferenceExprSyntax] = []
		private let context:SwiftSyntaxMacros.MacroExpansionContext
		internal init(context:SwiftSyntaxMacros.MacroExpansionContext) {
			self.context = context
			super.init(viewMode:.fixedUp)
		}
		internal override func visit(_ node:KeyPathComponentListSyntax) -> SyntaxVisitorContinueKind {
			guard node.count > 0 else {
				// if the key path expression does not have any components, we should not continue parsing.
				return .skipChildren
			}
			let referenceCollector = ReferenceCollector(viewMode:.fixedUp)
			referenceCollector.walk(node)
			keyPathComponents = referenceCollector.allDecls
			return .skipChildren
		}
	}
}