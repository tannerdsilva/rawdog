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

		// capture the attribute members as their expected compiler type - labeled expression list syntax
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

			// members of this type must be exclusively a DeclReferenceExprSyntax type
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

		// validate that there is more than one member
		guard members.count > 0 else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("attribute does not have any members")
			#endif
			throw Diagnostics.incorrectMemberCount(expected:1, found:0)
		}

		#if RAWDOG_MACRO_LOG
		mainLogger.info("returning \(members.count) members")
		#endif

		return members
	}

	// this verifies that the body of the attached class or structure contains the expect type and name of members.
	public static func validateAttachedDeclaration(expectingTypes:[DeclReferenceExprSyntax], _ declaration:some SwiftSyntax.DeclGroupSyntax) throws -> (TokenSyntax, DeclModifierListSyntax, [(String, String)]) {
		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsing attribute members...")
		defer {
			mainLogger.info("done parsing attribute members")
		}
		#endif
		
		// find the member block for the attached member (struct or class both should be handled)
		let parsedName:TokenSyntax
		let modifiers:DeclModifierListSyntax
		let memberBlockList:MemberBlockItemListSyntax
		if let asStructDecl = declaration.as(StructDeclSyntax.self) {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("attached declaration is a struct")
			#endif
			memberBlockList = asStructDecl.memberBlock.members
			modifiers = asStructDecl.modifiers
			parsedName = asStructDecl.name
		} else if let asClassDecl = declaration.as(ClassDeclSyntax.self) {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("attached declaration is a class")
			#endif
			memberBlockList = asClassDecl.memberBlock.members
			modifiers = asClassDecl.modifiers
			parsedName = asClassDecl.name
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
		var buildNamesAndNameRefs = [(String, String)]()
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
			
			// validate that the member name matches the expected name
			guard memberName == expectedName else {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("member name mismatch: expecting '\(expectedName)' but found '\(memberName)'")
				#endif
				throw Diagnostics.incorrectMemberType(expected:expectingTypes[i].baseName.text, found:memberName)
			}
			
			#if RAWDOG_MACRO_LOG
			mainLogger.info("member name matches.")
			#endif
			
			buildNamesAndNameRefs.append((idPattern.identifier.text, memberName))
			
			#if RAWDOG_MACRO_LOG
			mainLogger.info("added member name to buildNamesAndNameRefs: '\(idPattern.identifier.text)'")
			#endif
		}
		return (parsedName, modifiers, buildNamesAndNameRefs)
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		// get the variable type references that were defined in the arguments for this macro
		let (memberVariables) = try parseVariableTypeReferences(from: node)
		
		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsed \(memberVariables.count) members from attribute.")
		#endif
		
		// correlate these variable types with their associated variable names in the attached declaration
		let (parsedName, localModifiers, memberVariableNamesAndTypes) = try validateAttachedDeclaration(expectingTypes:memberVariables, declaration)
		
		#if RAWDOG_MACRO_LOG
		mainLogger.info("validated \(memberVariableNamesAndTypes.count) members from attached declaration.", metadata:["attached_entity_name":.string(parsedName.text)])
		#endif

		// create the primary initializer for the attached declaration
		var initializerParamList = FunctionParameterListSyntax()
		// var typeTypeBuild:[String] = []
		for (i, (curVarName, curVarType)) in memberVariableNamesAndTypes.reversed().enumerated().reversed() {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found member '\(curVarName)' of type '\(curVarType)'", metadata:["index":"\(i)", "comma_placed":(i == 0) ? "false" : "true"])
			#endif

			// build the function parameter syntax for this variable member
			let thisFParam:FunctionParameterSyntax
			if i == 0 {
				thisFParam = FunctionParameterSyntax("\(raw:curVarName):\(raw:curVarType)")
			} else {
				thisFParam = FunctionParameterSyntax("\(raw:curVarName):\(raw:curVarType), ")
			}
			initializerParamList.append(thisFParam)
		}
		
		// declare the primary initializer where each member is directly passed and stored in the new instance.
		let initDecl = DeclSyntax("""
		\(raw:localModifiers) init(\(raw:initializerParamList)) {
			\(raw:memberVariableNamesAndTypes.map { "self.\($0.0) = \($0.0)" }.joined(separator:"\n"))
		}
		""")

		return [initDecl]
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		// get the variable type references that were defined in the arguments for this macro 
		let (memberVariables) = try parseVariableTypeReferences(from: node)
		
		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsed \(memberVariables.count) members from attribute.")
		#endif
		
		// correlate these variable types with their associated variable names in the attached declaration
		let (parsedName, localModifiers, memberVariableNamesAndTypes) = try validateAttachedDeclaration(expectingTypes:memberVariables, declaration)

		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsed \(memberVariableNamesAndTypes.count) members from attached declaration.")
		#endif

		#if RAWDOG_MACRO_LOG
		mainLogger.info("created extension declaration for RAW_staticbuff conformance.")
		#endif

		// build the compare condition steps that will allow the macro type to implement RAW_comparable based on the underlying implementation of each member.
		var typeSizeSum:String = "("
		var compareConditionSteps:[String] = []
		for (i, (curVarName, curVarType)) in memberVariableNamesAndTypes.reversed().enumerated().reversed() {
			
			#if RAWDOG_MACRO_LOG
			mainLogger.info("adding compare condition for member '\(curVarName)' of type '\(curVarType)'", metadata:["index":"\(i)"])
			#endif

			// build the syntax that adds the static size of this type
			typeSizeSum += "\(curVarType).RAW_staticbuff_storetype"
			if i == 0 {
				typeSizeSum += ""
			} else {
				typeSizeSum += ", "
			}
			let appSyntax = """
			compareResult += \(curVarType).RAW_compare(lhs_data_seeking:&lhs_seeker, rhs_data_seeking:&rhs_seeker)
			guard compareResult == 0 else {
				return compareResult
			}
			"""
			compareConditionSteps.append(appSyntax)
		}
		typeSizeSum += ")"

		#if RAWDOG_MACRO_LOG
		mainLogger.info("built typeSizeSum argument strings: '\(typeSizeSum)'")
		#endif

		// build the initializer lines that will allow the macro type to implement RAW_staticbuff based on the underlying implementation of each member.
		var initializerLines:[String] = []
		var returnStoreLines = "("
		for (i, (curVarName, curVarType)) in memberVariableNamesAndTypes.reversed().enumerated().reversed() {
			initializerLines.append("self.\(curVarName) = \(curVarType)(RAW_staticbuff_storetype_seeking:&seeker)\n")
			switch i {
				case 0:
					returnStoreLines += "\(curVarName).RAW_staticbuff() )"
				default:
					returnStoreLines += "\(curVarName).RAW_staticbuff(), "
			}
		}

		// extend conformance to RAW_staticbuff since each of the children already conform to it.
		let rawSBDecl = try ExtensionDeclSyntax("""
			extension \(raw:parsedName):RAW_staticbuff {
				\(raw:localModifiers) typealias RAW_staticbuff_storetype = \(raw:typeSizeSum)

				/// exports the value to its raw byte representation.
				\(raw:localModifiers) func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
					var seeker = dest
					\(raw:memberVariableNamesAndTypes.map { "seeker = self.\($0.0).RAW_encode(dest:seeker)" }.joined(separator:"\n"))
					return seeker
				}

				/// provides access to the underlying memory of this value.
				\(raw:localModifiers) func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
					return try withUnsafePointer(to:\(raw:returnStoreLines)) { ptr in
						return try accessFunc(ptr, MemoryLayout<Self.RAW_staticbuff_storetype>.size)
					}
				}

				/// returns underlying memory of this value
				\(raw:localModifiers) func RAW_staticbuff() -> RAW_staticbuff_storetype {
					return self.RAW_access { buff, _ in
						return buff.load(as:RAW_staticbuff_storetype.self)
					}
				}

				/// initialize afrom the given raw buffer representation.
				\(raw:localModifiers) init(RAW_staticbuff_storetype ptr:UnsafeRawPointer) {
					var seeker = ptr
					\(raw:initializerLines.joined(separator:"\n"))
				}
			}
		""")

		// extend conformance to RAW_comparable since each of the children already conform to it.
		let extensionDecl = try ExtensionDeclSyntax("""
			extension \(raw:parsedName):RAW_comparable {
				/// sorts based on its native IEEE 754 representation and not its lexical representation.
				\(raw:localModifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
					var lhs_seeker = lhs_data
					var rhs_seeker = rhs_data
					var compareResult:Int32 = 0
					\(raw:compareConditionSteps.joined(separator:"\n"))
					return compareResult
				}
			}

		""")
		return [extensionDecl, rawSBDecl]
	}
}