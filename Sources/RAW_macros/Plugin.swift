// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct RAW_macros:CompilerPlugin {
	let providingMacros:[Macro.Type] = [
		RAW_convertible_string_type_macro_depricated.self,
		RAW_convertible_string_type_macro_v2.self,
		RAW_staticbuff_floatingpoint_type_macro.self,
		RAW_staticbuff_fixedwidthinteger_type_macro.self,
		RAW_staticbuff_bytes_macro.self,
		RAW_staticbuff_concat_macro.self
	]
}

internal struct ExpectedStructAttachment:Swift.Error, DiagnosticMessage {
	private let foundType:SyntaxProtocol.Type
	internal var message:String { "this macro expects to be attached to a struct declaration. instead, found type \(String(describing:foundType))." }
	internal var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"expected_struct_attachment")}
	internal var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
	internal init(found:SyntaxProtocol.Type) {
		self.foundType = found
	}
}

// captures all of the identifier types.
internal class IdTypeLister:SyntaxVisitor {
	internal var listedIDTypes:Set<IdentifierTypeSyntax> = []
	override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
		listedIDTypes.insert(node)
		return .skipChildren
	}
}

// captures the single identifier type listed in a generic argument clause.
internal final class SingleTypeGenericArgumentFinder:SyntaxVisitor {
	internal var foundType:IdentifierTypeSyntax? = nil
	override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
		guard node.count == 1 else {
			return .skipChildren
		}
		let idScanner = IdTypeLister(viewMode:.sourceAccurate)
		idScanner.walk(node)
		foundType = idScanner.listedIDTypes.first
		return .skipChildren
	}
}


internal final class StructFinder:SyntaxVisitor {
	var structDecl:StructDeclSyntax? = nil
	override func visit(_ node:StructDeclSyntax) -> SyntaxVisitorContinueKind {
		structDecl = node
		return .skipChildren
	}
}


internal func isMarkedSendable(_ declaration:StructDeclSyntax, withInheritanceClause:UnsafeMutablePointer<InheritanceClauseSyntax?>? = nil) -> Bool {
	let sendableFinder = InheritedTypeFinder(viewMode:.sourceAccurate)
	sendableFinder.walk(declaration)
	if withInheritanceClause != nil {
		withInheritanceClause!.pointee = sendableFinder.inheritanceClause
	}
	if sendableFinder.inheritedTypes["Sendable"] != nil {
		return true
	} else {
		return false
	}
}


// do not use on syntax that my contain multiple 
internal final class InheritedTypeFinder:SyntaxVisitor {
	internal var inheritanceClause:InheritanceClauseSyntax? = nil
	internal var inheritedTypes:[String:InheritedTypeSyntax] = [:]
	override func visit(_ node:InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
		if inheritanceClause == nil {
			inheritanceClause = node
			return .visitChildren
		} else {
			return .skipChildren
		}
	}
	override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
		guard let parent = node.parent?.as(InheritedTypeSyntax.self) else {
			return .skipChildren
		}
		inheritedTypes[node.name.text] = parent
		return .skipChildren
	}
}

/// identifies the type that a macro is attached to.
internal final class AttachedMemberTypeIdentifier:SyntaxVisitor {
	internal enum AttachedType {
		case structType(StructDeclSyntax)
		case classType(ClassDeclSyntax)
		case enumType(EnumDeclSyntax)
		case protocolType(ProtocolDeclSyntax)
	}
	internal var foundType:AttachedType? = nil
	override func visit(_ node:StructDeclSyntax) -> SyntaxVisitorContinueKind {
		foundType = .structType(node)
		return .skipChildren
	}
	override func visit(_ node:ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		foundType = .classType(node)
		return .skipChildren
	}
	override func visit(_ node:EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		foundType = .enumType(node)
		return .skipChildren
	}
	override func visit(_ node:ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		foundType = .protocolType(node)
		return .skipChildren
	}
}

internal final class VariableDeclLister:SyntaxVisitor {
	var varDecls = [VariableDeclSyntax]()
	override func visit(_ node:VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		varDecls.append(node)
		return .skipChildren
	}
	override func visit(_ node:CodeBlockSyntax) -> SyntaxVisitorContinueKind {
		return .skipChildren
	}
}

internal final class AccessorBlockLister:SyntaxVisitor {
	internal var accessorBlocks = [AccessorBlockSyntax]()
	override func visit(_ node:AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
		accessorBlocks.append(node)
		return .skipChildren
	}
}

internal final class FunctionFinder:SyntaxVisitor {
	internal var validMatches:Set<String> = []
	internal var funcDecl:[FunctionDeclSyntax] = []
	override func visit(_ node:FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		guard validMatches.contains(node.name.text) else {
			return .skipChildren
		}
		funcDecl.append(node)
		return .visitChildren
	}
}

internal final class FunctionParameterLister:SyntaxVisitor {
	internal var parameters:[FunctionParameterSyntax] = []
	override func visit(_ node:FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		parameters.append(node)
		return .skipChildren
	}
}

internal final class ReturnClauseFinder:SyntaxVisitor {
	internal var returnClause:ReturnClauseSyntax? = nil
	override func visit(_ node:ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		returnClause = node
		return .skipChildren
	}
}

internal final class FunctionEffectSpecifiersFinder:SyntaxVisitor {
	internal var effectSpecifier:FunctionEffectSpecifiersSyntax? = nil
	override func visit(_ node:FunctionEffectSpecifiersSyntax) -> SyntaxVisitorContinueKind {
		effectSpecifier = node
		return .skipChildren
	}
}

internal class StaticModifierFinder:SyntaxVisitor {
	internal var foundStaticModifier:DeclModifierSyntax? = nil
	override func visit(_ node:DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		guard node.name.text == "static" else {
			return .skipChildren
		}
		foundStaticModifier = node
		return .skipChildren
	}
}

internal struct RAW_staticbuff {
	internal enum UsageMode {
		case bytes(Int)
		case types([IdentifierTypeSyntax])
	}
	internal class SyntaxFinder:SyntaxVisitor {
		internal var found:AttributeSyntax? = nil
		internal var usageMode:UsageMode? = nil
		override func visit(_ node:AttributeSyntax) -> SyntaxVisitorContinueKind {
			guard let attr = node.attributeName.as(IdentifierTypeSyntax.self) else {
				return .skipChildren
			}
			guard attr.name.text == "RAW_staticbuff" else {
				return .skipChildren
			}
			guard node.arguments != nil else {
				return .skipChildren
			}
			found = node
			return .visitChildren
		}
		override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
			guard let firstItem = node.first else {
				return .skipChildren
			}
			guard let firstLabel = firstItem.label else {
				return .skipChildren
			}
			switch firstLabel.text {
				case "bytes":
					guard let isInt = firstItem.expression.as(IntegerLiteralExprSyntax.self) else {
						return .skipChildren
					}
					guard let byteCount = Int(isInt.literal.text) else {
						return .skipChildren
					}
					usageMode = .bytes(byteCount)
				case "concat":
					guard let _ = firstItem.expression.as(TypeExprSyntax.self) else {
						return .skipChildren
					}
					let idScanner = IdTypeLister(viewMode:.sourceAccurate)
					idScanner.walk(node)
					usageMode = .types(idScanner.listedIDTypes.map { $0 })
				default:
					return .skipChildren
			}
			return .skipChildren
		}
	}
}
internal func generateZeroLiteralExpression(byteCount:UInt16) -> SwiftSyntax.TupleExprSyntax {
	var buildContents = LabeledExprListSyntax()
	var i:UInt16 = 0
	while i < byteCount {
		let labeledExpr = LabeledExprSyntax(expression:IntegerLiteralExprSyntax(literal:.integerLiteral("0")), trailingComma:i + 1 < byteCount ? TokenSyntax.commaToken() : nil)
		buildContents.append(labeledExpr)
		i += 1
	}
	return TupleExprSyntax(leftParen:TokenSyntax.leftParenToken(), elements:buildContents, rightParen:TokenSyntax.rightParenToken())
}
internal func generateUnsignedByteTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	return generateTypeExpression(typeSyntax:IdentifierTypeSyntax(name:.identifier("UInt8")), byteCount:byteCount)
}
fileprivate func generateTypeExpression(typeSyntax:IdentifierTypeSyntax, byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	var buildContents = TupleTypeElementListSyntax()
	var i:UInt16 = 0
	while i < byteCount {
		var byteTypeElement = TupleTypeElementSyntax(type:typeSyntax)
		byteTypeElement.trailingComma = i + 1 < byteCount ? TokenSyntax.commaToken() : nil
		buildContents.append(byteTypeElement)
		i += 1
	}
	return TupleTypeSyntax(leftParen:TokenSyntax.leftParenToken(), elements:buildContents, rightParen:TokenSyntax.rightParenToken())
}
