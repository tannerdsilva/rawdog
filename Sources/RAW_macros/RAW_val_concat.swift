import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_val_concat")
#endif

public struct ConcatBufferTypeMacro:MemberMacro, ExtensionMacro {
	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		/// thrown when a type of syntax is expected but a different type is found.
		/// - parameter expected: the type of syntax expected.
		/// - parameter found: the type of syntax found.
		case unexpectedSyntaxStructure(SyntaxProtocol.Type, SyntaxProtocol.Type)

		/// thrown when the attached declaration is not a struct or class.
		case invalidAttachedDeclaration

		/// thrown when the number of members in the attribute does not match the number of members in the attached declaration.
		case incorrectMemberCount(expected:Int, found:Int)

		/// thrown when the type of a member in the attribute does not match the type of the member in the attached declaration.
		case incorrectMemberType(expected:String, found:String)

		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .unexpectedSyntaxStructure(_, _):
					return "RAW_val_concat.unexpectedSyntaxStructure"
				case .invalidAttachedDeclaration:
					return "RAW_val_concat.invalidAttachedDeclaration"
				case .incorrectMemberCount(_, _):
					return "RAW_val_concat.incorrectMemberCount"
				case .incorrectMemberType(_, _):
					return "RAW_val_concat.incorrectMemberType"
			}
		}

		public var message:String {
			switch self {
				case .unexpectedSyntaxStructure(let expected, let found):
					return "this macro expects \(expected) but found \(found)."
				case .invalidAttachedDeclaration:
					return "this macro expects the attached declaration to be a struct or class."
				case .incorrectMemberCount(let expected, let found):
					return "this macro expects \(expected) members but found \(found)."
				case .incorrectMemberType(let expected, let found):
					return "this macro expects member type \(expected) but found \(found)."
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_macros", id:self.did)
		}
	}

	/// lists all the variable type references in the attribute.
	public static func parseVariableTypeReferences(from node:SwiftSyntax.AttributeSyntax) throws -> [DeclReferenceExprSyntax] {
		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsing attribute members...")
		defer {
			mainLogger.info("done parsing attribute members")
		}
		#endif
		guard let attributeNumber = node.arguments?.as(LabeledExprListSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("attribute does not have a LabeledExprListSyntax")
			#endif
			throw Diagnostics.unexpectedSyntaxStructure(LabeledExprListSyntax.self, type(of:node.arguments!))
		}
		#if RAWDOG_MACRO_LOG
		mainLogger.critical("parsed members '\(attributeNumber)'")
		#endif
		var members:[DeclReferenceExprSyntax] = []
		for member in attributeNumber {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("parsing member '\(member)'")
			#endif
			guard let member = member.expression.as(DeclReferenceExprSyntax.self) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member '\(member)' is not a DeclReferenceExprSyntax")
				#endif
				throw Diagnostics.unexpectedSyntaxStructure(DeclReferenceExprSyntax.self, type(of:member.expression))
			}
			#if RAWDOG_MACRO_LOG
			let memberName = member.baseName.text
			mainLogger.info("identified member name: '\(memberName)'")
			#endif
			members.append(member)
		}

		#if RAWDOG_MACRO_LOG
		mainLogger.info("returning \(members.count) members")
		#endif
		return members
	}

	public static func validateAttachedDeclaration(expectingTypes:[DeclReferenceExprSyntax], _ declaration:some SwiftSyntax.DeclGroupSyntax) throws -> [(IdentifierPatternSyntax, DeclReferenceExprSyntax)] {
		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsing attribute members...")
		defer {
			mainLogger.info("done parsing attribute members")
		}
		#endif
		
		// find the member block for the attached member (struct or class both should be handled)
		let memberBlockList:MemberBlockItemListSyntax
		if let asStructDecl = declaration.as(StructDeclSyntax.self) {
			memberBlockList = asStructDecl.memberBlock.members
		} else if let asClassDecl = declaration.as(ClassDeclSyntax.self) {
			memberBlockList = asClassDecl.memberBlock.members
		} else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("attached declaration is not a struct or class")
			#endif
			throw Diagnostics.invalidAttachedDeclaration
		}

		#if RAWDOG_MACRO_LOG
		mainLogger.info("identified member list containing \(memberBlockList.count) members.")
		#endif

		guard memberBlockList.count == expectingTypes.count else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("member count mismatch: expecting \(expectingTypes.count) members but found \(memberBlockList.count)")
			#endif
			throw Diagnostics.incorrectMemberCount(expected:expectingTypes.count, found:memberBlockList.count)
		}

		// build a list of the member variable names and their associated type references
		var buildNamesAndNameRefs = [(IdentifierPatternSyntax, DeclReferenceExprSyntax)]()
		for (i, member) in memberBlockList.enumerated() {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("parsing member '\(member)'")
			#endif
			guard let member = member.as(MemberBlockItemSyntax.self) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member '\(member)' is not a MemberBlockItemSyntax")
				#endif
				throw Diagnostics.unexpectedSyntaxStructure(DeclSyntax.self, type(of:member))
			}
			guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member '\(member)' is not a VariableDeclSyntax")
				#endif
				throw Diagnostics.unexpectedSyntaxStructure(VariableDeclSyntax.self, type(of:member.decl))
			}
			guard let idPattern = variableDecl.bindings.first!.pattern.as(IdentifierPatternSyntax.self) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member '\(member)' is not a VariableDeclSyntax with a valid pattern binding")
				#endif
				throw Diagnostics.unexpectedSyntaxStructure(IdentifierPatternSyntax.self, type(of:variableDecl.bindings.first!.pattern))
			}
			guard let typeAnnotation = variableDecl.bindings.first!.typeAnnotation?.as(TypeAnnotationSyntax.self) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member '\(member)' is not a VariableDeclSyntax with a valid pattern binding")
				#endif
				throw Diagnostics.unexpectedSyntaxStructure(TypeAnnotationSyntax.self, type(of:variableDecl.bindings.first!.typeAnnotation!))
			}
			guard let memberName = typeAnnotation.type.as(IdentifierTypeSyntax.self)?.name.text else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member '\(member)' is not a VariableDeclSyntax with a valid pattern binding")
				#endif
				throw Diagnostics.unexpectedSyntaxStructure(VariableDeclSyntax.self, type(of:member))
			}
			let expectedName = expectingTypes[i].baseName.text
			#if RAWDOG_MACRO_LOG
			mainLogger.info("identified member type: '\(memberName)'", metadata:["expecting":.string(expectedName)])
			#endif
			guard memberName == expectedName else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member name mismatch: expecting '\(expectedName)' but found '\(memberName)'")
				#endif
				throw Diagnostics.incorrectMemberType(expected:expectingTypes[i].baseName.text, found:memberName)
			}
			#if RAWDOG_MACRO_LOG
			mainLogger.info("member name matches.")
			#endif
			buildNamesAndNameRefs.append((idPattern, expectingTypes[i]))
			#if RAWDOG_MACRO_LOG
			mainLogger.info("added member name to buildNamesAndNameRefs: '\(idPattern.identifier.text)'")
			#endif
		}
		return buildNamesAndNameRefs
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		// get the variable type references that were defined in the arguments for this macro 
		let memberVariables = try parseVariableTypeReferences(from: node)
		
		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsed \(memberVariables.count) members from attribute.")
		#endif
		
		// correlate these variable types with their associated variable names in the attached declaration
		let memberVariableNamesAndTypes = try validateAttachedDeclaration(expectingTypes:memberVariables, declaration)
		
		#if RAWDOG_MACRO_LOG
		mainLogger.info("validated \(memberVariableNamesAndTypes.count) members from attached declaration.")
		#endif

		for (curVarName, curVarType) in memberVariableNamesAndTypes {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found member '\(curVarName.identifier.text)' of type '\(curVarType.baseName.text)'")
			#endif
		}
		return []
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		let myVars = try parseVariableTypeReferences(from: node)
		return []
	}
}