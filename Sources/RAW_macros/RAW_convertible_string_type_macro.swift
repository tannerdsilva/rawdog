// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

internal struct RAW_convertible_string_type_macro_depricated:MemberMacro, ExtensionMacro {
	fileprivate struct ConvertToCurrentSyntax:DiagnosticMessage {
		let message:String = "this macro pattern has been deprecated. please use the new macro pattern."
		let severity:DiagnosticSeverity = .error
		let diagnosticID:MessageID = MessageID(domain:"RAW_convertible_string_type_macro_depricated", id:"stringtype_message_convert_to_current_syntax")
		fileprivate struct FixItDiagnostic:FixItMessage {
		    let message:String = "convert to the new macro usage pattern."
		    let fixItID: SwiftDiagnostics.MessageID = MessageID(domain:"RAW_convertible_string_type_macro_depricated", id:"stringtype_fixit_convert_to_current_syntax")
		}
	}
	fileprivate final class LegacyNodeExtractor:SyntaxVisitor {
		let context:SwiftSyntaxMacros.MacroExpansionContext
		fileprivate init(context:SwiftSyntaxMacros.MacroExpansionContext) {
			self.context = context
			super.init(viewMode:.sourceAccurate)
		}
		override func visit(_ node:AttributeListSyntax) -> SyntaxVisitorContinueKind {
			return .visitChildren
		}
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
		override func visit(_ node:AttributeSyntax) -> SyntaxVisitorContinueKind {
			let idlister = IdTypeFinderFirstName(viewMode:.sourceAccurate)
			idlister.walk(node.attributeName)
			guard idlister.foundIdentifierTypeName != nil else {
				return .skipChildren
			}
			guard idlister.foundIdentifierTypeName!.name.text == "RAW_convertible_string_type" else {
				return .skipChildren
			}

			let genericIdlister = IdTypeFinderFirstGenericArgument(viewMode:.sourceAccurate)
			genericIdlister.walk(node.attributeName)
			guard genericIdlister.foundIdentifierTypeFirstGenericArgument != nil else {
				return .skipChildren
			}

			let labeledExprListFinder = LabeledExprListFinder(viewMode:.sourceAccurate)
			labeledExprListFinder.walk(node)
			guard labeledExprListFinder.foundFirstDeclReferenceExpr != nil else {
				return .skipChildren
			}

			// isolate the syntax that defines the unicode type and strip it of all trivia.
			var unicodeType:DeclReferenceExprSyntax = labeledExprListFinder.foundFirstDeclReferenceExpr!
			unicodeType.leadingTrivia = ""
			unicodeType.trailingTrivia = ""
			let unicodeTypeText = unicodeType.baseName.text
			// translate the unicode type into its new syntax form
			let newGenericArgumentList = GenericArgumentSyntax(argument:IdentifierTypeSyntax(name:"\(raw:unicodeTypeText)"))

			// isolate the syntax that defines the backing type and strip it of all trivia.
			var backingType:IdentifierTypeSyntax = idlister.foundIdentifierTypeName!
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
				],
			)
			context.diagnose(diagnostic)
			return .skipChildren
		}
	}
	fileprivate class NodeParser:SyntaxVisitor {
		var intType:IdentifierTypeSyntax? = nil
		var unicodeType:DeclReferenceExprSyntax? = nil
		override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
			guard node.count == 1 else {
				return .skipChildren
			}
			return .visitChildren
		}
		override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
			guard node.count == 1 else {
				return .skipChildren
			}
			return .visitChildren
		}
		override func visit(_ node:GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
			let idlister = IdTypeLister(viewMode:.sourceAccurate)
			idlister.walk(node)
			guard idlister.listedIDTypes.count == 1 else {
				return .skipChildren
			}
			if intType == nil {
				intType = idlister.listedIDTypes.first
			}
			return .visitChildren
		}
		override func visit(_ node:MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
			// verify that this member access expression has a period with a self token after the period\
			guard node.period == TokenSyntax.periodToken() && node.declName.baseName == TokenSyntax.keyword(Keyword.`self`) else {
				return .skipChildren
			}
			return .visitChildren
		}
		override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
			guard node.baseName != TokenSyntax.keyword(Keyword.`self`) else {
				return .skipChildren
			}
			if unicodeType == nil {
				unicodeType = node
			}
			return .skipChildren
		}
	}
	static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let np = NodeParser(viewMode:.sourceAccurate)
		np.walk(node)
		guard let intType = np.intType, let unicodeType = np.unicodeType else {
			return []
		}
		let structFinder = StructFinder(viewMode:.sourceAccurate)
		structFinder.walk(declaration)
		guard let structDecl = structFinder.structDecl else {
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:declaration)
			return []
		}

		let bytesVarName = context.makeUniqueName("encoded_bytes_raw")
		let countVarName = context.makeUniqueName("encoded_bytes_count")
		
		var buildDecls = [DeclSyntax]()
		buildDecls.append(DeclSyntax("""
			/// the length of the string without the null terminator
			private let \(countVarName):size_t
		"""))
		buildDecls.append(DeclSyntax("""
			/// this is stored with a terminating byte for C compatibility but this null terminator is not included in the count variable that this instance stores
			private var \(bytesVarName):[UInt8]
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) typealias RAW_convertible_unicode_encoding = \(unicodeType)
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) typealias RAW_integer_encoding_impl = \(intType)
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) consuming func makeIterator() -> RAW_encoded_unicode_iterator<Self> {
				return RAW_encoded_unicode_iterator(\(bytesVarName), encoding:Self.self)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) init(RAW_decode: UnsafeRawPointer, count: size_t) {
				let asBuffer = UnsafeBufferPointer<UInt8>(start:RAW_decode.assumingMemoryBound(to:UInt8.self), count:count)
				\(bytesVarName) = [UInt8](asBuffer)
				\(countVarName) = count
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) init(_ string:consuming String.UnicodeScalarView) {	
				// a character may produce multiple code units. count the required number of code units first.
				var byteCount:size_t = 0
				var bytes:[UInt8] = []
				for curScalar in string {
					RAW_convertible_unicode_encoding.encode(curScalar) { codeUnit in
						RAW_integer_encoding_impl(RAW_native:codeUnit).RAW_access { buffer in
							bytes.append(contentsOf:buffer)
							byteCount += buffer.count
						}
					}
				}
				\(countVarName) = byteCount
				\(bytesVarName) = bytes
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) borrowing func RAW_access<R, E>(_ body:(UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try \(bytesVarName).RAW_access(body)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) mutating func RAW_access_mutating<R, E>(_ body:(UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try \(bytesVarName).RAW_access_mutating(body)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) borrowing func RAW_encode(count:inout size_t) {
				count += \(countVarName)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
				return \(bytesVarName).RAW_encode(dest:dest)
			}
		"""))
		return buildDecls
	}

	static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		return [
			try ExtensionDeclSyntax("""
				extension \(type):RAW_encoded_unicode {}
			""")
		]
	}
}