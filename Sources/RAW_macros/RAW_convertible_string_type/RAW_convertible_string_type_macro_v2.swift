// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

fileprivate struct AttachedMemberDiagnostics {
	// diagnostic error that is thrown when the node usage could not be properly parsed
	fileprivate struct UnknownNodeUsage:Swift.Error, DiagnosticMessage {
		fileprivate let message:String = "could not determine the syntax that this macro was declared with. please complete the macro declaration."
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_unknown_node_usage")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
	}	
	// diagnostic error that is thrown when the attached body could not be parsed effectively.
	fileprivate struct UnknownAttachedMemberType:Swift.Error, DiagnosticMessage {
		fileprivate let message:String
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_unidentified_type")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init(found:SyntaxProtocol.Type) {
			self.message =  "could not determine the syntax that the macro was attached to. expected to find a struct declaration but found '\(String(describing:found))' instead."
		}
	}

	// message to notify the user that the attached member is not a struct.
	fileprivate struct IncorrectAttachedMemberType:DiagnosticMessage {
		fileprivate let foundType:AttachedMemberTypeIdentifier.AttachedType
		fileprivate let message:String
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_incorrect_type")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init(found:AttachedMemberTypeIdentifier.AttachedType) {
			self.foundType = found
			switch found {
				case .classType(let classDecl):
					self.message = "attached member \(classDecl.name.text) is a class. expected to find a struct."
				case .protocolType(let protocolDecl):
					self.message = "attached member \(protocolDecl.name.text) is a protocol. expected to find a struct."
				case .enumType(let enumDecl):
					self.message = "attached member \(enumDecl.name.text) is an enum. expected to find a struct."
				case .structType(let structDecl):
					self.message = "attached member \(structDecl.name.text) is a struct. expected to find a struct."
			}
		}

		// fixit message to convert the attached member to a struct.
		fileprivate struct FixItDiagnostic:FixItMessage {
			fileprivate let message:String
			fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_fix_convert_to_struct_decl")
			fileprivate let fromOldType:AttachedMemberTypeIdentifier.AttachedType
			fileprivate init(fromOldType:AttachedMemberTypeIdentifier.AttachedType) {
				self.fromOldType = fromOldType
				switch fromOldType {
					case .classType(let classDecl):
						self.message = "convert \(classDecl.name.text) from class to struct."
					case .protocolType(let protocolDecl):
						self.message = "convert \(protocolDecl.name.text) from protocol to struct."
					case .enumType(let enumDecl):
						self.message = "convert \(enumDecl.name.text) from enum to struct."
					default:
						self.message = "convert unknown from struct to struct."
				}
			}
		}
	}

	// message to notify the user that private modifiers cannot be used on the attached member.
	fileprivate struct IncorrectAttachedMemberModifier:Swift.Error, DiagnosticMessage {
	    fileprivate let message:String
	    fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_incorrect_modifier")
	    fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init(unsupportedModifier:DeclModifierSyntax) {
			self.message = "'\(unsupportedModifier.name.text)' modifier is not supported. please remove this modifier from the attached member and consider using a modifier such as 'fileprivate' or 'internal' to manage access."
		}
		
		fileprivate struct FixItDiagnostic:FixItMessage {
			fileprivate let message:String
			fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_fix_incorrect_modifier")
			fileprivate init(replace:DeclModifierSyntax, withSyntax:DeclModifierSyntax?) {
				self.message = "replace \(replace.name.text) modifier with \(withSyntax?.name.text ?? "nothing")."
			}
		}
	}

	fileprivate static func validateAttachedMemberBasics(declaration:some SwiftSyntax.DeclGroupSyntax, node:SwiftSyntax.AttributeSyntax, context:some SwiftSyntaxMacros.MacroExpansionContext, addDiagnostics:Bool) -> StructDeclSyntax? {
		// parse for the attached declaration. the attached declaration must be a struct. if the attached syntax is not a struct declaration, offer valid suggestions to convert it to a struct.
		let typeIdentifier = AttachedMemberTypeIdentifier(viewMode:.sourceAccurate)
		typeIdentifier.walk(declaration)
		let asStruct:StructDeclSyntax
		switch typeIdentifier.foundType {
			case nil:
				if addDiagnostics == true {
					context.addDiagnostics(from:AttachedMemberDiagnostics.UnknownAttachedMemberType(found:declaration.syntaxNodeType), node:node)
				}
				return nil
			case .some(let id):
				switch id {
					case .structType(let structDecl):
						// if the attached declaration is a struct, then we can use it after doing some validation.

						// validate that the attached struct does not have a private modifier.
						var containsPrivate:DeclModifierSyntax? = nil
						for mod in structDecl.modifiers {
							if mod.name.text == "private" {
								containsPrivate = mod
							}
						}
						if containsPrivate != nil {
							// private modifier found. this is not allowed.
							if addDiagnostics == true {
								let internalDecl = DeclModifierSyntax(name:"internal", trailingTrivia:.space)
								let fileprivateDecl = DeclModifierSyntax(name:"fileprivate", trailingTrivia:.space)
								let publicDecl = DeclModifierSyntax(name:"public", trailingTrivia:.space)
								let diagnosticMessage = Diagnostic(
									node:containsPrivate!,
									message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier(unsupportedModifier:containsPrivate!),
									fixIts:[
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:nil), oldNode:containsPrivate!, newNode:DeclSyntax("")),
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:fileprivateDecl), oldNode:containsPrivate!, newNode:fileprivateDecl),
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:internalDecl), oldNode:containsPrivate!, newNode:internalDecl),
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:publicDecl), oldNode:containsPrivate!, newNode:publicDecl)
									]
								)
								context.diagnose(diagnosticMessage)
							}
							return nil
						}
					
						// basic struct validation complete.
						asStruct = structDecl
						break
					case .classType(let classDecl):
						// attached class type. need to diagnose then return
						var replacementSyntax = StructDeclSyntax(attributes:classDecl.attributes, modifiers:classDecl.modifiers, name:classDecl.name, genericParameterClause:classDecl.genericParameterClause, inheritanceClause:classDecl.inheritanceClause, memberBlock:classDecl.memberBlock, trailingTrivia:Trivia.space)
						replacementSyntax.structKeyword.trailingTrivia = .space
						if addDiagnostics == true {
							let diagnosticMessage = Diagnostic(
								node:classDecl.name,
								message:AttachedMemberDiagnostics.IncorrectAttachedMemberType(found:typeIdentifier.foundType!),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberType.FixItDiagnostic(fromOldType:id), oldNode:classDecl, newNode:replacementSyntax),
								]
							)
							context.diagnose(diagnosticMessage)
						}
						return nil
					case .protocolType(let protocolDecl):
						// attached protocol type. need to diagnose then return
						var replacementSyntax = StructDeclSyntax(attributes:protocolDecl.attributes, modifiers:protocolDecl.modifiers, name:protocolDecl.name, inheritanceClause:protocolDecl.inheritanceClause, memberBlock:protocolDecl.memberBlock, trailingTrivia:Trivia.space)
						replacementSyntax.structKeyword.trailingTrivia = .space
						if addDiagnostics == true {
							let diagnosticMessage = Diagnostic(
								node:protocolDecl.name,
								message:AttachedMemberDiagnostics.IncorrectAttachedMemberType(found:typeIdentifier.foundType!),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberType.FixItDiagnostic(fromOldType:id), oldNode:protocolDecl, newNode:replacementSyntax),
								]
							)
							context.diagnose(diagnosticMessage)
						}
						return nil
					case .enumType(let enumDecl):
						// attached enum type. need to diagnose then return
						var replacementSyntax = StructDeclSyntax(modifiers:enumDecl.modifiers, name:enumDecl.name, inheritanceClause:enumDecl.inheritanceClause, memberBlock:enumDecl.memberBlock, trailingTrivia:Trivia.space)
						replacementSyntax.structKeyword.trailingTrivia = .space
						if addDiagnostics == true {
							let diagnosticMessage = Diagnostic(
								node:enumDecl.name,
								message:AttachedMemberDiagnostics.IncorrectAttachedMemberType(found:typeIdentifier.foundType!),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberType.FixItDiagnostic(fromOldType:id), oldNode:enumDecl, newNode:replacementSyntax),
								]
							)
							context.diagnose(diagnosticMessage)
						}
						return nil
				}
		}
		return asStruct
	}
}

internal struct RAW_convertible_string_type_macro_v2:MemberMacro, ExtensionMacro {
    static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let (structDecl, _, _) = Self.validate(declaration:declaration, node:node, context:context, addDiagnostics:false) else {
			// unable to validate the attached member. return nil.
			return []
		}

		return [
			try! ExtensionDeclSyntax("""
				extension \(raw:structDecl.name.text):RAW_encoded_unicode {}
			"""),
		]
    }

	fileprivate final class UnicodeTypeExtractor:SyntaxVisitor {
		private final class IdTypeLister:SyntaxVisitor {
			var firstIDType:IdentifierTypeSyntax? = nil
			override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
				guard firstIDType == nil else {
					return .skipChildren
				}
				firstIDType = node
				return .skipChildren
			}
		}
		var foundUnicodeType:IdentifierTypeSyntax? = nil
		override func visit(_ node:GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
			guard foundUnicodeType == nil else {
				return .skipChildren
			}
			let idScanner = IdTypeLister(viewMode:.sourceAccurate)
			idScanner.walk(node)
			foundUnicodeType = idScanner.firstIDType
			return .skipChildren
		}
	}
	fileprivate final class BackingTypeExtractor:SyntaxVisitor {
		private final class DeclRefFinder:SyntaxVisitor {
			var foundDeclRef:DeclReferenceExprSyntax? = nil
			override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
				guard foundDeclRef == nil else {
					return .skipChildren
				}
				foundDeclRef = node
				return .skipChildren
			}
		}
		var foundDeclReferenceExpr:DeclReferenceExprSyntax? = nil
		override func visit(_ node:MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
			guard foundDeclReferenceExpr == nil && node.base != nil else {
				return .skipChildren
			}
			let declRefFinder = DeclRefFinder(viewMode:.sourceAccurate)
			declRefFinder.walk(node.base!)
			guard declRefFinder.foundDeclRef != nil else {
				return .skipChildren
			}
			foundDeclReferenceExpr = declRefFinder.foundDeclRef!
			return .skipChildren
		}		
	}

	fileprivate static func validate(declaration:some SwiftSyntax.DeclGroupSyntax, node:SwiftSyntax.AttributeSyntax, context:some SwiftSyntaxMacros.MacroExpansionContext, addDiagnostics:Bool) -> (attached:StructDeclSyntax, encoding:IdentifierTypeSyntax, backingType:DeclReferenceExprSyntax)? {
		// validate the attached body
		guard let asStruct = AttachedMemberDiagnostics.validateAttachedMemberBasics(declaration:declaration, node:node, context:context, addDiagnostics:addDiagnostics) else {
			// unable to validate the attached member. return nil.
			return nil
		}

		// determine the node configuration. first, find the unicode type.
		let encodingType = UnicodeTypeExtractor(viewMode:.sourceAccurate)
		encodingType.walk(node)
		guard encodingType.foundUnicodeType != nil else {
			if addDiagnostics == true {
				context.addDiagnostics(from:AttachedMemberDiagnostics.UnknownNodeUsage(), node:node)
			}
			return nil
		}

		let backingTypeFinder = BackingTypeExtractor(viewMode:.sourceAccurate)
		backingTypeFinder.walk(node)
		guard let foundBackingType = backingTypeFinder.foundDeclReferenceExpr else {
			if addDiagnostics == true {
				context.addDiagnostics(from:AttachedMemberDiagnostics.UnknownNodeUsage(), node:node)
			}
			return nil
		}
		return (attached:asStruct, encoding:encodingType.foundUnicodeType!, backingType:foundBackingType)
	}

	static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let (structDecl, unicodeType, backingType) = Self.validate(declaration:declaration, node:node, context:context, addDiagnostics:true) else {
			// unable to validate the attached member. return nil.
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
			\(structDecl.modifiers) typealias RAW_integer_encoding_impl = \(backingType)
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
}