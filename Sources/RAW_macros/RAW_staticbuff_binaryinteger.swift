import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_staticbuff_binaryinteger_macro")
#endif

extension SwiftSyntax.FunctionDeclSyntax {
	static func validateAsRAW_compare(_ node:SwiftSyntax.FunctionDeclSyntax) -> Swift.Error? {
		// validate that this function is a valid implementation of the static RAW_buffer
		// validate that there are only two arguments in the function declaration and that the arguments are of type UnsafeRawPointer.
		let paramList = node.signature.parameterClause.parameters

		// validate that the function is static
		guard node.modifiers.contains(where: { $0.name.text == "static" }) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("found non-static RAW_compare function declaration")
			#endif
			return RAW_staticbuff_binaryinteger_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
		}

		/// validate that the function has two arguments.
		guard paramList.count == 2 else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("found invalid number of arguments in RAW_compare function declaration")
			#endif
			return RAW_staticbuff_binaryinteger_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
		}
		guard let lhsParam = paramList.first!.as(FunctionParameterSyntax.self), let lhsType = lhsParam.type.as(IdentifierTypeSyntax.self), let rhsParam = paramList.last!.as(FunctionParameterSyntax.self), let rhsType = rhsParam.type.as(IdentifierTypeSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("found invalid argument type in RAW_compare function declaration")
			#endif
			return RAW_staticbuff_binaryinteger_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
		}

		guard lhsParam.firstName.text == "lhs_data" && rhsParam.firstName.text == "rhs_data" else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("found invalid argument name in RAW_compare function declaration")
			#endif
			return RAW_staticbuff_binaryinteger_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
		}
		
		guard lhsType.name.text == "UnsafeRawPointer" && rhsType.name.text == "UnsafeRawPointer" else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("found invalid argument type in RAW_compare function declaration")
			#endif
			return RAW_staticbuff_binaryinteger_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
		}
		return nil
	}
}
public struct RAW_staticbuff_binaryinteger_macro:MemberMacro, ExtensionMacro {

	// the primary tool that parses the macro node and determines how it should expand based on user configuration input.
	internal class MacroSyntaxVisitor:SyntaxVisitor {

		internal var integerType:String? = nil
		internal var integerBytes:Int? = nil
		internal var isBigEndian:Bool? = nil

		override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
			guard node.count == 1 else {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("expected only one generic argument, but got \(node.count)")
				#endif
				return .skipChildren
			}
			return .visitChildren
		}

		override func visit(_ node:GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
			guard let idType = node.argument.as(IdentifierTypeSyntax.self) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("expected an IdentifierTypeSyntax for the generic argument, but got \(node.argument)")
				#endif
				return .skipChildren
			}
			integerType = idType.name.text
			return .visitChildren
		}

		override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
			switch node.label?.text {
				case "bits":
					guard let intLiteral = node.expression.as(IntegerLiteralExprSyntax.self) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected an IntegerLiteralExprSyntax for the bits argument, but got \(node.expression)")
						#endif
						return .skipChildren
					}
					guard let bits = Int(intLiteral.literal.text) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected an integer literal for the bits argument, but got \(intLiteral.digits)")
						#endif
						return .skipChildren
					}
					guard bits % 8 == 0 else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected a multiple of 8 for the bits argument, but got \(bits)")
						#endif
						return .skipChildren
					}
					integerBytes = bits / 8
					return .visitChildren
				case "bigEndian":
					guard let boolLiteral = node.expression.as(BooleanLiteralExprSyntax.self) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected a BooleanLiteralExprSyntax for the bigEndian argument, but got \(node.expression)")
						#endif
						return .skipChildren
					}
					isBigEndian = boolLiteral.literal.text == "true"
					return .visitChildren
				default:
					#if RAWDOG_MACRO_LOG
					mainLogger.error("unexpected label \(node.label?.text ?? "<nil>")")
					#endif
					return .skipChildren
			}
		}
	}

	internal class AttachedSyntaxVisitor:SyntaxVisitor {
		internal var attachedStructName:TokenSyntax? = nil
		internal var inheritedTypes:Set<InheritedTypeSyntax> = []
		internal var modifierList:DeclModifierListSyntax = []
		internal var implementedFunctions:Set<FunctionDeclSyntax> = []
		internal var error:Swift.Error? = nil

		override func visit(_ funcDecl:FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
			switch error {
				case .none:
					// accept a function that expresses the RAW_compare requirement
					error = FunctionDeclSyntax.validateAsRAW_compare(funcDecl)
					guard error == nil else {
						error = RAW_staticbuff_binaryinteger_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
						return .skipChildren
					}
					implementedFunctions.update(with:funcDecl)
					return .visitChildren
				case .some(_):
					return .skipChildren
			}
		}

		override func visit(_ node:DeclModifierListSyntax) -> SyntaxVisitorContinueKind {
			switch error {
				case .none:
					modifierList = node
					return .visitChildren
				case .some(_):
					return .skipChildren
			}
		}
		override func visit(_ node:StructDeclSyntax) -> SyntaxVisitorContinueKind {
			switch error {
				case .none:
					attachedStructName = node.name
					return .visitChildren
				case .some(_):
					return .skipChildren
			}
		}
		override func visit(_ node:InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
			switch error {
				case .none:
					inheritedTypes.update(with:node)
					return .visitChildren
				case .some(_):
					return .skipChildren
			}
		}
	}
	
	internal struct UsageConfiguration {
		internal var integerType:String
		internal var integerBytes:Int
		internal var isBigEndian:Bool
	}

	/// parses the available syntax to determine how this macro should expand (based on user configuration).
	internal static func parseUsageConfig(node:SwiftSyntax.AttributeSyntax, attachedTo:SwiftSyntax.DeclGroupSyntax) throws -> UsageConfiguration {
		let parser = MacroSyntaxVisitor(viewMode:.sourceAccurate)
		parser.walk(node)
		guard let integerType = parser.integerType else {
			throw Diagnostics.missingArgument(node, "integerType")
		}
		guard let bytes = parser.integerBytes else {
			throw Diagnostics.missingArgument(node, "bits")
		}
		guard let isBigEndian = parser.isBigEndian else {
			throw Diagnostics.missingArgument(node, "isBigEndian")
		}
		return UsageConfiguration(integerType:integerType, integerBytes:bytes, isBigEndian:isBigEndian)
	}
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
       let pconfig = try Self.parseUsageConfig(node:node, attachedTo:declaration)
		let attachedParser = AttachedSyntaxVisitor(viewMode:.sourceAccurate)
		attachedParser.walk(declaration)
		guard let attachedStructName = attachedParser.attachedStructName else {
			throw Diagnostics.missingStructDecl(declaration)
		}
		let inheritedTypes = attachedParser.inheritedTypes
		let typeExpression = generateUnsignedByteTypeExpression(byteCount:UInt16(pconfig.integerBytes))
		var buildSyntax = [DeclSyntax]()
		buildSyntax.append(DeclSyntax("""
			\(attachedParser.modifierList) typealias RAW_staticbuff_storetype = \(typeExpression)
		"""))
		buildSyntax.append(DeclSyntax("""
			\(attachedParser.modifierList) var RAW_staticbuff:RAW_staticbuff_storetype
		"""))
		buildSyntax.append(DeclSyntax("""
			\(attachedParser.modifierList) init?(RAW_staticbuff ptr: UnsafeRawPointer) {
				self.RAW_staticbuff = ptr.load(as:RAW_staticbuff_storetype.self)
			}
		"""))
	    return []
    }

    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        defer {
			fatalError("\(context)")
		}
		return []
    }

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		case missingArgument(SwiftSyntax.AttributeSyntax, String)
		case mustBeIntegerLiteral(SwiftSyntax.ExprSyntax)
		case missingStructDecl(SwiftSyntax.DeclGroupSyntax)
		case invalidFunctionOverride(String)

		/// the severity of the diagnostic.
		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .missingArgument(_, _):
					return "RAW_staticbuff_binaryinteger_macro.missingArgument"
				case .mustBeIntegerLiteral(_):
					return "RAW_staticbuff_binaryinteger_macro.mustBeIntegerLiteral"
				case .missingStructDecl(_):
					return "RAW_staticbuff_binaryinteger_macro.missingStructDecl"
				case .invalidFunctionOverride(_):
					return "RAW_staticbuff_binaryinteger_macro.invalidFunctionOverride"
			}
		}

		public var message:String {
			switch self {
				case .missingArgument(let node, let argName):
					return "missing argument \(argName) for \(node)"
				case .mustBeIntegerLiteral(let node):
					return "expected an integer literal for \(node)"
				case .missingStructDecl(let node):
					return "expected a struct declaration for \(node)"
				case .invalidFunctionOverride(let funcName):
					return "invalid function override for \(funcName)"
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_staticbuff_binaryinteger_macro", id:self.did)
		}
	}
}

fileprivate func generateUnsignedByteTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
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
