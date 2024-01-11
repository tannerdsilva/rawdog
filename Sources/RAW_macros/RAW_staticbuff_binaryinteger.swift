import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_staticbuff_binaryinteger_macro")
#endif

// fileprivate func validateAsRAW_compare(_ node:SwiftSyntax.FunctionDeclSyntax, context: some SwiftSyntaxMacros.MacroExpansionContext) {
// 	// validate that this function is a valid implementation of the static RAW_buffer
// 	// validate that there are only two arguments in the function declaration and that the arguments are of type UnsafeRawPointer.
// 	let paramList = node.signature.parameterClause.parameters
	
// 	// validate the function name
// 	guard node.name.text == "RAW_compare" else {
// 		#if RAWDOG_MACRO_LOG
// 		mainLogger.critical("found invalid function name in RAW_compare function declaration")
// 		#endif
// 		context.addDiagnostics(from:RAW_staticbuff_fixedwidthinteger_explicit_macro.Diagnostics.invalidFunctionOverride(.invalidFunctionName(node.name.text)), node:node)
// 		return
// 	}

// 	// validate that the function is static
// 	guard node.modifiers.contains(where: { $0.name.text == "static" }) else {
// 		#if RAWDOG_MACRO_LOG
// 		mainLogger.critical("found non-static RAW_compare function declaration")
// 		#endif
// 		context.addDiagnostics(from:RAW_staticbuff_fixedwidthinteger_explicit_macro.Diagnostics.invalidFunctionOverride(.missingStaticModifier), node:node.modifiers)
// 		return
// 	}
	
// 	/// validate that the function has two arguments.
// 	guard paramList.count == 2 else {
// 		#if RAWDOG_MACRO_LOG
// 		mainLogger.critical("found invalid number of arguments in RAW_compare function declaration")
// 		#endif
// 		return RAW_staticbuff_fixedwidthinteger_explicit_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
// 	}
// 	guard let lhsParam = paramList.first!.as(FunctionParameterSyntax.self), let lhsType = lhsParam.type.as(IdentifierTypeSyntax.self), let rhsParam = paramList.last!.as(FunctionParameterSyntax.self), let rhsType = rhsParam.type.as(IdentifierTypeSyntax.self) else {
// 		#if RAWDOG_MACRO_LOG
// 		mainLogger.critical("found invalid argument type in RAW_compare function declaration")
// 		#endif
// 		return RAW_staticbuff_fixedwidthinteger_explicit_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
// 	}

// 	guard lhsParam.firstName.text == "lhs_data" && rhsParam.firstName.text == "rhs_data" else {
// 		#if RAWDOG_MACRO_LOG
// 		mainLogger.critical("found invalid argument name in RAW_compare function declaration")
// 		#endif
// 		return RAW_staticbuff_fixedwidthinteger_explicit_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
// 	}
	
// 	guard lhsType.name.text == "UnsafeRawPointer" && rhsType.name.text == "UnsafeRawPointer" else {
// 		#if RAWDOG_MACRO_LOG
// 		mainLogger.critical("found invalid argument type in RAW_compare function declaration")
// 		#endif
// 		return RAW_staticbuff_fixedwidthinteger_explicit_macro.Diagnostics.invalidFunctionOverride("RAW_compare")
// 	}
// 	return nil
// }

internal struct RAW_staticbuff_fixedwidthinteger_explicit_macro:MemberMacro, ExtensionMacro {

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
			switch integerType {
				case .none:
					#if RAWDOG_MACRO_LOG
					mainLogger.notice("found integer type \(idType.name.text). parsing will continue.")
					#endif
					integerType = idType.name.text
					return .visitChildren
				case .some(let intType):
					#if RAWDOG_MACRO_LOG
					mainLogger.error("expected only one generic argument, but got \(node.argument)")
					#endif
					return .skipChildren
			}
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
						mainLogger.error("expected an integer literal for the bits argument, but got \(intLiteral.literal)")
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
					isBigEndian = (boolLiteral.literal.text == "true")
					return .visitChildren
				default:
					#if RAWDOG_MACRO_LOG
					mainLogger.error("unexpected label \(node.label?.text ?? "<nil>")")
					#endif
					return .skipChildren
			}
		}
	}

	// primary interpretation tool for the attached syntax.
	internal class AttachedSyntaxVisitor:SyntaxVisitor {
		internal enum AttachedType {
			case structDecl(String)
		}
		
		internal var mode:AttachedType? = nil
		internal var inheritedTypes:Set<IdentifierTypeSyntax> = []
		internal var modifierList:DeclModifierListSyntax = []

		override func visit(_ node:DeclModifierListSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.notice("found modifier list \(node). parsing will continue.")
			#endif
			modifierList = node
			return .visitChildren
		}

		override func visit(_ node:StructDeclSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.notice("found struct declaration \(node.name). parsing will continue.")
			#endif
			mode = .structDecl(node.name.text)
			return .visitChildren
		}

		override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.notice("found inherited type \(node). parsing will continue.")
			#endif
			inheritedTypes.update(with:node)
			return .visitChildren
		}
	}
	
	internal struct UsageConfiguration {
		internal let structName:String
		internal let integerType:String
		internal let integerBytes:Int
		internal let isBigEndian:Bool
		internal var endianFunctionName:String {
			return isBigEndian ? "bigEndian" : "littleEndian"
		}
		internal var inheritedTypes:Set<IdentifierTypeSyntax> = []
		internal var modifierList:DeclModifierListSyntax = []
	}

	/// parses the available syntax to determine how this macro should expand (based on user configuration).
	internal static func parseUsageConfig(node:SwiftSyntax.AttributeSyntax, attachedTo declaration:some SyntaxProtocol, context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> UsageConfiguration {
		let parser = MacroSyntaxVisitor(viewMode:.sourceAccurate)
		parser.walk(node)
		guard let integerType = parser.integerType else {
			context.addDiagnostics(from:Diagnostics.missingArgument(node, "integerType"), node:node)
			throw Diagnostics.missingArgument(node, "integerType")
		}
		guard let bytes = parser.integerBytes else {
			context.addDiagnostics(from:Diagnostics.missingArgument(node, "bits"), node:node)
			throw Diagnostics.missingArgument(node, "bits")
		}
		guard let isBigEndian = parser.isBigEndian else {
			context.addDiagnostics(from:Diagnostics.missingArgument(node, "bigEndian"), node:node)
			throw Diagnostics.missingArgument(node, "bigEndian")
		}

		let attachedParser = AttachedSyntaxVisitor(viewMode:.sourceAccurate)
		attachedParser.walk(declaration)
		let sn:String
		switch attachedParser.mode {
			case .none:
				context.addDiagnostics(from:Diagnostics.missingStructDeclOrExtension(declaration), node:declaration)
				throw Diagnostics.missingStructDeclOrExtension(declaration)
			case .some(.structDecl(let structName)):
				#if RAWDOG_MACRO_LOG
				mainLogger.notice("found struct declaration \(structName). parsing will continue.")
				#endif
				sn = structName
		}
		return UsageConfiguration(structName:sn, integerType:integerType, integerBytes:bytes, isBigEndian:isBigEndian, inheritedTypes:attachedParser.inheritedTypes, modifierList:attachedParser.modifierList)
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let pconfig = try Self.parseUsageConfig(node:node, attachedTo:declaration, context:context)
		
		let inheritedTypes = pconfig.inheritedTypes
		let typeExpression = generateUnsignedByteTypeExpression(byteCount:UInt16(pconfig.integerBytes))
		var buildSyntax = [DeclSyntax]()
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) typealias RAW_staticbuff_storetype = \(typeExpression)
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) var RAW_staticbuff:RAW_staticbuff_storetype
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				self.RAW_staticbuff = ptr.load(as:RAW_staticbuff_storetype.self)
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) init?(_ native:\(raw:pconfig.integerType)) {
				self = withUnsafePointer(to:native.\(raw:pconfig.endianFunctionName)) { ptr in
					return Self(RAW_staticbuff:ptr)
				}
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
				return withUnsafePointer(to:RAW_staticbuff) { ptr in
					return RAW_memcpy(dest, ptr, MemoryLayout<RAW_staticbuff_storetype>.size)!.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) func RAW_access<R>(_ accessor: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
				return try withUnsafePointer(to:RAW_staticbuff) { ptr in
					return try accessor(ptr, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
				let lhs = \(raw:pconfig.integerType)(\(raw:pconfig.endianFunctionName):lhs_data.load(as:\(raw:pconfig.integerType).self))
				let rhs = \(raw:pconfig.integerType)(\(raw:pconfig.endianFunctionName):rhs_data.load(as:\(raw:pconfig.integerType).self))
				if lhs < rhs {
					return -1
				} else if lhs > rhs {
					return 1
				} else {
					return 0
				}
			}
		"""))
		if inheritedTypes.contains(where: { $0.name.text == "Hashable" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) func hash(into hasher:inout Hasher) {
					RAW_access { buffPtr, _ in
						let asBuffer = UnsafeRawBufferPointer(start:buffPtr, count:MemoryLayout<RAW_staticbuff_storetype>.size)
						hasher.combine(bytes:asBuffer)
					}
				}
			"""))
		}
		if inheritedTypes.contains(where: { $0.name.text == "Equatable" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) static func == (lhs:Self, rhs:Self) -> Bool {
					return withUnsafePointer(to:lhs) { lhsPointer in
						return withUnsafePointer(to:rhs) { rhsPointer in
							return Self.RAW_compare(lhs_data:lhsPointer, rhs_data:rhsPointer) == 0
						}
					}
				}
			"""))
		}
		if inheritedTypes.contains(where: { $0.name.text == "Comparable" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) static func < (lhs:Self, rhs:Self) -> Bool {
					return withUnsafePointer(to:lhs) { lhsPointer in
						return withUnsafePointer(to:rhs) { rhsPointer in
							return Self.RAW_compare(lhs_data:lhsPointer, rhs_data:rhsPointer) < 0
						}
					}
				}
			"""))
		}

		if inheritedTypes.contains(where: { $0.name.text == "ExpressibleByIntegerLiteral" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) init(integerLiteral value:\(raw:pconfig.integerType)) {
					self = withUnsafePointer(to:value.\(raw:pconfig.endianFunctionName)) { ptr in
						return Self(RAW_staticbuff:ptr)
					}
				}
			"""))
		}

		if inheritedTypes.contains(where: { $0.name.text == "ExpressibleByArrayLiteral" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) init(arrayLiteral elements:UInt8...) {
					self = Self(RAW_staticbuff:[UInt8](elements))
				}
			"""))
		}
		
		return buildSyntax
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		let pconfig = try Self.parseUsageConfig(node:node, attachedTo:declaration, context:context)
		return [try ExtensionDeclSyntax ("""
			extension \(raw:pconfig.structName):RAW_staticbuff {}
		""")]
	}

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		case missingArgument(SwiftSyntax.AttributeSyntax, String)
		case mustBeIntegerLiteral(SwiftSyntax.ExprSyntax)
		case missingStructDeclOrExtension(SyntaxProtocol)

		case unexpectedExtensionName(found:String, expected:String)
		case unexpectedStructName(found:String, expected:String)

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
				case .missingStructDeclOrExtension(_):
					return "RAW_staticbuff_binaryinteger_macro.missingStructDecl"
				case .unexpectedExtensionName(_, _):
					return "RAW_staticbuff_binaryinteger_macro.unexpectedExtensionName"
				case .unexpectedStructName(_, _):
					return "RAW_staticbuff_binaryinteger_macro.unexpectedStructName"
			}
		}

		public var message:String {
			switch self {
				case .missingArgument(let node, let argName):
					return "missing argument \(argName) for \(node)"
				case .mustBeIntegerLiteral(let node):
					return "expected an integer literal for \(node)"
				case .missingStructDeclOrExtension(let node):
					return "expected a struct declaration for \(node)"
				case .unexpectedExtensionName(let found, let expected):
					return "expected extension of \(expected), but got \(found)"
				case .unexpectedStructName(let found, let expected):
					return "expected struct name \(expected), but got \(found)"
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
